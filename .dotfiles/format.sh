#!/usr/bin/env bash

echo "Running SwiftFormat"

swiftformat . --baseconfig .dotfiles/.swiftformat-base
