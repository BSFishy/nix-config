package main

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"os/user"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
)

func getUser() (*user.User, error) {
	if createUser {
		return user.Lookup(userName)
	} else {
		return user.Current()
	}
}

func getIds() (int, int, error) {
	u, err := getUser()
	if err != nil {
		return 0, 0, fmt.Errorf("failed to lookup user: %s", err)
	}

	uid, err := strconv.ParseInt(u.Uid, 10, 32)
	if err != nil {
		return 0, 0, fmt.Errorf("failed to parse uid: %s", err)
	}

	gid, err := strconv.ParseInt(u.Gid, 10, 32)
	if err != nil {
		return 0, 0, fmt.Errorf("failed to parse gid: %s", err)
	}

	return int(uid), int(gid), nil
}

func mkdir(path string) error {
	if err := os.MkdirAll(path, 0755); err != nil {
		return fmt.Errorf("failed to create setup output dir: %s", err)
	}

	uid, gid, err := getIds()
	if err != nil {
		return err
	}

	if err = os.Chown(outputDir, uid, gid); err != nil {
		return fmt.Errorf("failed to change owner of setup output dir: %s", err)
	}
	return nil
}

func doCreateUser() error {
	u, err := user.Current()
	if err != nil {
		return fmt.Errorf("failed to get current user: %s", err)
	}

	if u.Uid != "0" {
		return fmt.Errorf("must be run as root")
	}

	cmd := exec.Command("useradd", "-m", userName)
	printCommand(cmd)

	if !dryRun {
		if err := cmd.Run(); err != nil {
			return fmt.Errorf("failed to create the account: %s", err)
		}
	}

	cmd = exec.Command("chpasswd")
	printCommand(cmd)

	if !dryRun {
		cmd.Stdin = bytes.NewBufferString(fmt.Sprintf("%s:%s", userName, userPassword))
		if err := cmd.Run(); err != nil {
			return fmt.Errorf("failed to set the user password: %s", err)
		}
	}

	if userSudo {
		cmd = exec.Command("usermod", "-aG", "sudo", userName)
		printCommand(cmd)

		if !dryRun {
			if err := cmd.Run(); err != nil {
				return fmt.Errorf("failed to add the user to the sudo group: %s", err)
			}
		}
	}

	return nil
}

var (
	homeDir   string
	outputDir string
)

func setupHomeDirectory() error {
	u, err := getUser()
	if err != nil {
		return fmt.Errorf("failed to lookup user: %s", err)
	}

	homeDir = u.HomeDir
	outputDir = filepath.Join(homeDir, ".dotfiles-setup")

	if err = mkdir(outputDir); err != nil {
		return fmt.Errorf("failed to create setup output dir: %s", err)
	}

	return nil
}

func command(name string, args ...string) (*exec.Cmd, error) {
	cmd := exec.Command(name, args...)
	if createUser {
		u, err := user.Lookup(userName)
		if err != nil {
			return nil, fmt.Errorf("failed to lookup user: %s", err)
		}

		uid, err := strconv.ParseUint(u.Uid, 10, 32)
		if err != nil {
			return nil, fmt.Errorf("failed to parse uid: %s", err)
		}

		gid, err := strconv.ParseUint(u.Gid, 10, 32)
		if err != nil {
			return nil, fmt.Errorf("failed to parse gid: %s", err)
		}

		cmd.SysProcAttr = &syscall.SysProcAttr{
			Credential: &syscall.Credential{
				Uid: uint32(uid),
				Gid: uint32(gid),
			},
		}

		cmd.Env = append(cmd.Env, fmt.Sprintf("HOME=%s", u.HomeDir), fmt.Sprintf("USER=%s", u.Username))

		if pathEnv, ok := os.LookupEnv("PATH"); ok {
			cmd.Env = append(cmd.Env, fmt.Sprintf("PATH=%s", pathEnv))
		}
	}

	return cmd, nil
}

func setPermissions(f *os.File) error {
	uid, gid, err := getIds()
	if err != nil {
		return err
	}

	if err = f.Chown(uid, gid); err != nil {
		return fmt.Errorf("failed to change owner of %s: %s", f.Name(), err)
	}

	return nil
}

func clone(repo string, dir string) error {
	cmd, err := command("git", "clone", repo, dir)
	if err != nil {
		return err
	}

	printCommand(cmd)

	if dryRun {
		return nil
	}

	splitDir := strings.Split(dir, string(os.PathSeparator))
	outputFile, err := os.Create(filepath.Join(outputDir, fmt.Sprintf("dotfiles-clone-%s.log", splitDir[len(splitDir)-1])))
	if err != nil {
		return fmt.Errorf("failed to create clone output log: %s", err)
	}

	defer outputFile.Close()

	if err := setPermissions(outputFile); err != nil {
		return fmt.Errorf("failed to set log permissions: %s", err)
	}

	cmd.Stdout = outputFile
	cmd.Stderr = outputFile

	return cmd.Run()
}

func cloneDotfiles() error {
	return clone("https://github.com/BSFishy/nix-config.git", filepath.Join(homeDir, "dotfiles"))
}

func nix(args ...string) (*exec.Cmd, error) {
	extraArgs := []string{"--extra-experimental-features", "nix-command flakes"}
	extraArgs = append(extraArgs, args...)
	return command("nix", extraArgs...)
}

func setupHomeManager(configuration string) error {
	cmd, err := nix("run", "home-manager/master", "--", "switch", "--flake", fmt.Sprintf("%s/dotfiles#%s", homeDir, configuration), "-b", "backup")
	if err != nil {
		return err
	}

	printCommand(cmd)

	if dryRun {
		return nil
	}

	outputFile, err := os.Create(filepath.Join(outputDir, "home-manager-switch.log"))
	if err != nil {
		return fmt.Errorf("failed to create clone output log: %s", err)
	}

	defer outputFile.Close()

	if err := setPermissions(outputFile); err != nil {
		return fmt.Errorf("failed to set log permissions: %s", err)
	}

	cmd.Stdout = outputFile
	cmd.Stderr = outputFile

	return cmd.Run()
}

func setupNixos(configuration string) error {
	cmd, err := command("nixos-rebuild", "switch", "--flake", fmt.Sprintf("%s/dotfiles#%s", homeDir, configuration))
	if err != nil {
		return err
	}

	printCommand(cmd)

	if dryRun {
		return nil
	}

	outputFile, err := os.Create(filepath.Join(outputDir, "nixos-switch.log"))
	if err != nil {
		return fmt.Errorf("failed to create clone output log: %s", err)
	}

	defer outputFile.Close()

	if err := setPermissions(outputFile); err != nil {
		return fmt.Errorf("failed to set log permissions: %s", err)
	}

	cmd.Stdout = outputFile
	cmd.Stderr = outputFile

	return cmd.Run()
}

func setupExtras() error {
	if err := clone("https://github.com/BSFishy/init.lua.git", filepath.Join(homeDir, ".config", "nvim")); err != nil {
		return fmt.Errorf("failed to clone nvim config: %s", err)
	}

	if err := mkdir(filepath.Join(homeDir, "projects")); err != nil {
		return fmt.Errorf("failed to create projects dir: %s", err)
	}

	if err := clone("https://github.com/BSFishy/shells.git", filepath.Join(homeDir, "shells")); err != nil {
		return fmt.Errorf("failed to clone shells project: %s", err)
	}

	return nil
}
