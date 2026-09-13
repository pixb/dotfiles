# dotfiles

My dotfiles.

```shell
stow -t ~ .
```

## Add ranger config to stow manager example

```shell
cd ~/dotfiles
mkdir -p ranger/.config
```

```shell
cp -r ~/.config/ranger ranger/.config
```

```shell
stow -t ~ ranger
```
