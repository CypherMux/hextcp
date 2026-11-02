# Contributing to hextcp

First things first thank you for considering contributing to `hextcp`! It is people like you that make the open-source community such an amazing place to learn, inspire, create, and just be a part of in general.

## How to Report a Bug

If you find a bug such as a socket type not parsing correctly or a formatting glitch for example, please open an Issue on Github.

Before opening an issue, please check if it had already been reported first. When you create an issue, please include the following:

* Your Linux distribution *(Arch Linux,Ubuntu,etc..)*

*  The exact command in which you ran *(e.g, `sudo hextcp -a -p`)*.

*  The expected output versus the actual output you had received.

### Suggesting Enhancements

If you have an idea for a new feature, open an Issue with the tag `[Feature Request]`. Describe exactly what you want the tool to do and why it would be useful for a real-world security analysis.

##  How to Submit a Pull Request

*  **1.** Fork the repository and create your branch from `main`.

*  **2.** If you have added code that should be tested, add tests *(if applicable to the situation)*.

*  **3.** Ensure the script still passes `shellcheck` *(if you use it)*.

*  **4.** Update the `README.md` with details of changes to the interface *(like if you were to add a new flag for example)*.

*  **5.** Issue the pull request!

## Code Styling

To keep the codebase clean and readable, please follow these guidelines:

*  **100% Native Bash:** Do not use external dependencies like *Python*, `jq`, or `netcat`. We want this tool to work on minimal and restricted Linux systems as much as we can.

*  **Comment your logic:** If you are adding a complex hex conversion or a new `awk` parsing block, explain *why* it works in the comments.

*  **Indentation:** Use indentation while writing your code, preferably one to two.

*  **Variables:** Always wrap variables in quotes *(e.g, `"$VARIABLE"`)* to prevent word splitting and globbing issues.

## License

*By contributing, you agree that your contributions will be licensed under its MIT license.*
