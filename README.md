Myplanet Ariadne cookbook
=======================

This cookbook is intended to perform the "last mile" of configuration
needed to bring the Ariadne environment to a fully provisioned state for
development of the Myplanet Digital website.

Follow the instructions in [Ariadne's official
README][ariadne-project-setup] to setup the project.

Currently, only Myplanet employees will be able to complete the build,
as it requires a `drush sql-sync` from Acquia's servers. We hope to make
it completely bootable with dummy content in the future.

Features
--------

  - This project makes use of the `clean=true` environment variable. To
    wipe the data and rebuild the site, simply run `clean=true vagrant
    provision`. (Requires the "develop" branch of Ariadne.)

<!-- Links -->
   [ariadne-project-setup]: https://github.com/myplanetdigital/ariadne#ariadne-project
