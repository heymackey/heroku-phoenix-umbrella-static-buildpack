Heroku Phoenix Umbrella Static Buildpack
========================================

This buildpack is meant to be a replacement for https://github.com/gjaldon/heroku-buildpack-phoenix-static. This buildpack does not assume there is only one web application within the project and accepts a list of asset directories for which to compile assets.

### Features
* Deploys assets bundles for single or multiple Phoenix applications.
* Configure versions for Node and NPM
* Caches dependencies for quicker installs
* Allows override for custom deploy commands

Usage
-----

1. Create a Heroku instance for your project
    ```sh
    heroku apps:create my_heroku_app
    ```
2. Set and add the buildpacks for your Heroku app
    ```sh
    heroku buildpacks:set https://github.com/HashNuke/heroku-buildpack-elixir
    heroku buildpacks:add https://github.com/heymackey/heroku-phoenix-umbrella-static-buildpack
    ```
3. Deploy
    ```sh
    git push heroku master
    ```

Configuration
-------------
Create a `heroku_phoenix_umbrella_static_buildpack.config` file in the root of your project. This file will be treated as a bash script. If you don't specify a config file, the default configuration will be used.

Here's a full configuration with all the options:

```sh
#!/usr/bin/env bash

# Set the NodeJS version to be installed.
node_version=10.15.1

# Set the NPM version to be installed.
npm_version=6.4.1

# Comma delimitted list of application assets paths. By default the configuration uses `assets` which works for
# a vanilla Phoenix application where the root of the project is the application root as well.
assets_paths=assets

# Set whether or not to clean out the cache after the deploy.
clear_cache=false

```

Compile
-------

The default compile process is a basic Phoenix static asset deploy process, it looks something like this:

```sh
# in application assets dir
npm run deploy

# in application root
mix phx.digest
mix phx.digest.clean

```

This will deploy the static assets for each configured application in the buildpack according to the default Phoenix static asset deploy steps. If you wish to customize the deploy process for a given application, you need to define a `compile_static_assets.sh` file within the `assets` directory of the application you wish to customize. When a custom compile script is present, this buildpack will completely defer to that script. You can mix and match default and custom deploys for all the applications configured for deploy (i.e one app can leverage the defaults, while another may have a custom deploy script).

### Custom script environment variables

There are a few handy variables that will be available in your custom compile script you may need to reference:

```sh
$buildpack_root # This provides the full path to the root of the buildpack
$build_path # The full path to the build directory
$cache_path # The full path to the cache directory
$env_path # The full path to the environment directory
$package_root # The npm package root of the current application (i.e apps/some_app/assets)
$app_path # The root of the current application (i.e apps/some_app)
```

### Custom script available functions

There are also a few handy functions that will be available in your custom compile script to help with printing out information:

#### print_heading

The `print_heading` function will create a new line, then print an ascii arrow prepended to the given string. This allows you to output a heading in a format that matches the rest of the output.

```sh
print_heading "Doing custom compile"
```

Output:

```

-----> Doing custom compile
```

#### print_indented

The `print_indented` prints a string with empty spaces prepended to align the text output with the previous lines.

```sh
print_indented "Custom compile step message"
```

Output:

```
       Custom compile step message
```

#### read_indented

The `read_indented` function is similar to the `print_indented` except it's meant to be used when reading output from another file or process.

```sh
npm install | read_indented
```

Output:

```
       audited 494906 packages in 8.83s
       found 7 vulnerabilities (2 low, 5 moderate)
         run `npm audit fix` to fix them, or `npm audit` for details

```

#### print_error

The `print_error` function allows you to print red-colored output text for more noticeable failure messages. The given string will have `Error: ` prepended to the message.

```sg
print_error "Something bad happened"
```

Output (in red):

```
       Error: Something bad happened
```

#### print_success

The `print_success` function allows you to print green-colored output text for more noticeable success messages.

```sh
print_success "Woo hoo! all done!"
```

Output (in green):

```
       Woo hoo! all done!
```
