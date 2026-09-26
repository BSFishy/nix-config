#pragma once
#include "common.hpp"

constexpr bool topbar = true;
constexpr int paddingX = 8;
constexpr int paddingY = 2;
constexpr const char* font = "JetBrainsMono Nerd Font 11";
constexpr ColorScheme colorInactive = {Color(0xd0, 0xd0, 0xd0), Color(0x20, 0x20, 0x20)};
constexpr ColorScheme colorActive = {Color(0xff, 0xff, 0xff), Color(0x20, 0x20, 0x20)};
constexpr const char* termcmd[] = {"ghostty", nullptr};

static std::vector<std::string> tagNames = {
	"1", "2", "3", "4", "5", "6", "7", "8", "9",
};

constexpr Button buttons[] = {};
