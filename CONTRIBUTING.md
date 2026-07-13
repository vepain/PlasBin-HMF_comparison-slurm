# Contributing

**Table of content:**

* [Workspace](#workspace)
  * [VSCode users](#vscode-users)
* [Adding a new experiment script](#adding-a-new-experiment-script)
  * [1 - Add the core template sbatch script](#1---add-the-core-template-sbatch-script)
  * [2 - Add the environment script (for Fir)](#2---add-the-environment-script-for-fir)
  * [3 - Add script to init the environment (for Fir)](#3---add-script-to-init-the-environment-for-fir)
  * [4 - Document](#4---document)
* [Build the documentation](#build-the-documentation)
  * [Install](#install)
  * [Usage](#usage)
* [Git workflow](#git-workflow)
  * [Git conventions](#git-conventions)
  * [Git tools](#git-tools)
    * [Initialize the environment](#initialize-the-environment)
    * [Develop a feature](#develop-a-feature)
    * [Publish a release](#publish-a-release)

## Workspace

### VSCode users

For [VSCode] user, settings are in `.vscode/settings.json` and required extensions are listed in `.vscode/extensions.json`.

## Adding a new experiment script

### 1 - Add the core template sbatch script

In `src/scripts`:

* in a subdirectory if it corresponds to the same tool but with different command
  * e.g. `plaseval-gdv` has two commands `eval` and `comp`

Tasks:

1. Use conventional sbatch comment (do not change the CPU/MEM/TIME limits)
2. (If any) Declare user variables
3. Load base scripts (must be the same thing for all scripts)
4. Init the tool environment
5. Set the task arguments (using variables and functions from `filtree_layout.sh` and `utils.sh` scripts)
6. Register job ID
7. Run the tool (potentially create the output directory)

### 2 - Add the environment script (for Fir)

In `src/envs`:

* Prefer to use the same name as the tool for the script, e.g.`plaseval-gdv.sh`

Tasks:

1. As the environment script is sourced after the `config.sh`, you can use variables from the `filetree_layout.sh` script
2. If apptainer, be carefull if the tool is installed in the image, or is configurated to be run directly via `apptainer run` (see `src/envs/plaseval-gdv.sh` and `src/envs/unicycler.sh` for different examples)

### 3 - Add script to init the environment (for Fir)

Like building the apptainer image.

>[!IMPORTANT]
> According to the [Alliance Canadian Fir HPC cluster documentation](https://docs.alliancecan.ca/wiki/Python#Creating_virtual_environments_inside_of_your_jobs), virtual environment should be built everytime (i.e. for each array job task).
> That means do not build neither store the virtual environment in `envs` - this implies to not create a script to init the environment.

### 4 - Document

> [!WARNING]
> For [Zensical Studio VSCode extension] users, there is a known issue (<https://github.com/zensical/studio/issues/44>):
> even properly configurated, Markdown documents outside of `docs` (like this file) are considered as `Python Markdown` files.
> The `Python Markdown` file language is great for Markdown documents used by Zensical, but is not the best for "regular" Markdown.
> The temporarly solution is to able the [Zensical Studio VSCode extension] **only** when you are working on the Zensical documentation - otherwise disable it.

In `docs`:

1. In `docs/setup/envs`, document the Fir environment initialization script (if any)
   1. Add the entry to `docs/setup/envs/index.md`
2. In `docs/experiments`, document how to use the sbatch script.
   1. Add the entry to the navigation menu, see `nav` section in `./zensical.toml`

>[!TIP]
> Do not worry too much about the document structure, try one, we will change later if needed.

## Build the documentation

We use [Zensical] static website generator based on Markdown.

### Install

We use [uv] to run [Zensical] as a tool.

```sh
uvx --with-requirements requirements-doc.txt zensical --help
```

### Usage

Preview in live server

```sh
uvx --with-requirements requirements-doc.txt zensical serve
open http://localhost:8000 # May be different, use the adress given by the command in stdout
```

## Git workflow

### Git conventions

Branching conventions: [Default GitFlow conventions](https://danielkummer.github.io/git-flow-cheatsheet/)

Follow [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/) for commit messages

> [!TIP]
> If you use `VSCode`, you can install the [Conventional Commits VSCode extension](https://marketplace.visualstudio.com/items?itemName=vivaxy.vscode-conventional-commits).

### Git tools

[git-flow-next] for git branching template

#### Initialize the environment

```sh
git flow init -d
```

#### Develop a feature

Start a new feature:

```sh
git flow feature start <feature-name>
```

> [!NOTE]
> To give access to the feature to other developers, you must first publish it:
>
> ```sh
> git flow feature publish <feature-name>
> ```

Finish the feature:

* merges to the develop branch
* removes the feature branch

```sh
git flow feature finish <feature-name>
```

#### Publish a release

Create a release branch:

```bash
# Set the release number, e.g. by add a patch
lvl=patch # patch, minor, major... see with `uv version --help`
release=M.m.p # A release number

git flow release start $release
# To allow release commits by other developers
git flow release publish $release
```

Modify the `CHANGELOG.md` and commit:

```sh
git add --all
git commit -m "Prepare release $release"
```

Finish the release:

```sh
git flow release finish $release -m "New version $release"
git push origin develop
git push origin main
git push origin --tags
```

<!-- LINKS -->

[VSCode]: https://code.visualstudio.com/
[uv]: https://docs.astral.sh/uv/
[Zensical]: https://zensical.org
[Zensical Studio VSCode extension]: https://marketplace.visualstudio.com/items?itemName=zensical.zensical-studio
[git-flow-next]: https://github.com/gittower/git-flow-next
