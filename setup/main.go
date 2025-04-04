package main

import (
	"flag"
	"fmt"
	"os/user"
	"runtime"

	"github.com/charmbracelet/huh"
)

var dryRun bool

var (
	installationType      string
	dotfilesConfiguration string
	createUser            bool   = true
	userName              string = "matt"
	userPassword          string
	userSudo              bool = true
)

const (
	NIXOS        = "nixos"
	NIX_DARWIN   = "nix_darwin"
	HOME_MANAGER = "home_manager"
)

func main() {
	flag.BoolVar(&dryRun, "dry-run", false, "don't actually run any commands")
	flag.Parse()

	user, err := user.Lookup(userName)
	if err != nil {
		fmt.Printf("Failed to lookup user: %s\n", err)
	}

	createUser = user == nil

	osOption, validConfigurations := getValidConfigurations()

	fields := []huh.Field{
		huh.NewSelect[string]().
			Title("What type of Nix installation is this?").
			Options(
				osOption,
				huh.NewOption("Home Manager", HOME_MANAGER),
			).
			Value(&installationType),
		huh.NewSelect[string]().
			Title("Which configuration should be used?").
			Options(validConfigurations...).
			Value(&dotfilesConfiguration),
	}

	if runtime.GOOS == "linux" {
		fields = append(fields,
			huh.NewConfirm().
				Title("Should a new user be created?").
				Affirmative("Yes").
				Negative("No").
				Value(&createUser),
		)
	} else {
		createUser = false
	}

	form := huh.NewForm(
		huh.NewGroup(fields...),
		huh.NewGroup(
			huh.NewInput().
				Title("What should the user's name be?").
				Value(&userName),
			huh.NewInput().
				Title("What should the user's password be?").
				EchoMode(huh.EchoModePassword).
				Value(&userPassword),
			huh.NewConfirm().
				Title("Should the user be given the sudo group?").
				Affirmative("Yes").
				Negative("No").
				Value(&userSudo),
		).WithHideFunc(func() bool {
			return !createUser || runtime.GOOS != "linux"
		}),
	)

	err = form.Run()
	if err != nil {
		fatal("Failed to run form: %s\n", err)
	}

	fmt.Printf("dry run: %t\n", dryRun)
	fmt.Printf("installation: %s\n", installationType)
	fmt.Printf("config: %s\n", dotfilesConfiguration)
	fmt.Printf("create user: %t\n", createUser)
	if createUser {
		fmt.Printf("user name: %s\n", userName)
		fmt.Printf("user sudo: %t\n", userSudo)
	}

	if createUser {
		err = doCreateUser()
		if err != nil {
			fatal("Failed to create user: %s\n", err)
		}
	}

	err = setupHomeDirectory()
	if err != nil {
		fatal("Failed to identify home directory: %s\n", err)
	}

	err = cloneDotfiles()
	if err != nil {
		fatal("Failed to clone dotfiles: %s\n", err)
	}

	switch installationType {
	case NIXOS:
		panic("unimplemented")
	case NIX_DARWIN:
		panic("unimplemented")
	case HOME_MANAGER:
		setupHomeManager(dotfilesConfiguration)
	default:
		panic(fmt.Sprintf("invalid installation type: %s", installationType))
	}

	err = setupExtras()
	if err != nil {
		fatal("Failed to setup extras: %s\n", err)
	}

	fmt.Printf("%sSuccessfully set up! You may need to log out and back in for everything to work properly.%s\n", color(Green), reset)
}

func getValidConfigurations() (huh.Option[string], []huh.Option[string]) {
	switch runtime.GOOS {
	case "linux":
		return huh.NewOption("NixOS", NIXOS), []huh.Option[string]{
			huh.NewOption("Personal", "personal-linux"),
			huh.NewOption("Server", "server-linux"),
		}
	case "darwin":
		return huh.NewOption("Nix-Darwin", NIX_DARWIN), []huh.Option[string]{
			huh.NewOption("Work", "work-darwin"),
		}
	default:
		fatal("Unsupported OS\n")
	}

	panic("unreachable")
}
