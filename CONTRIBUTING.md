# Contributing

**Table of content:**

- [Workspace](#workspace)
  - [VSCode users](#vscode-users)
- [Documentations](#documentations)
  - [Install](#install)
  - [Usage](#usage)
- [Git workflow](#git-workflow)
  - [Git conventions](#git-conventions)
  - [Git tools](#git-tools)
    - [Initialize the environment](#initialize-the-environment)
    - [Develop a feature](#develop-a-feature)
    - [Publish a release](#publish-a-release)

## Workspace

### VSCode users

For [VSCode] user, settings are in `.vscode/settings.json` and required extensions are listed in `.vscode/extensions.json`.

## Documentations

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

- merges to the develop branch
- removes the feature branch

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
[git-flow-next]: https://github.com/gittower/git-flow-next
