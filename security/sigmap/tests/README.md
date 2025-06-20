# Brownie Tests

## Installing Brownie

Brownie can be installed via

```sh
pip install eth-brownie
```

Alternatively all required packages can be installed via

```sh
pip install -r requirements.txt
```

## Running the Tests

Tests can be run from this directory `./`

```sh
brownie test
```

Note you can add all the pytest parameters/flags e.g.

- `./tests/test_deploy.py`
- `-s`
- `-v`
- `-k <test_name>`

## Writing tests

The same as the old `pytest` style. Add a file named `tests_<blah>.py`
to the folder `./tests`.

Each individual test case in the file created above must be a function named
`test_<test_case>()`.

Checkout the [brownie docs](https://eth-brownie.readthedocs.io/en/stable/tests-pytest-intro.html)
for details on the syntax.

Note `print(dir(Object))` is a handy way to see available methods for a python object.

## Avalanche Fork Tests

This repo uses a fork of Avalanche at block 21927598.

Before the tests may be run we need to add this network to brownie.
Run the following command but change `<INFURA_KEY>` to be your Infura key (or change the URL if using another provider but keep the `@21927598`).

```sh
brownie networks add development avax-fork-21927598 cmd=ganache-cli host=http://127.0.0.1 fork=https://avalanche-mainnet.infura.io/v3/<INFURA_KEY>@21927598 accounts=10 mnemonic=brownie port=8545
```
