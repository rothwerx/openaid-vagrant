openaid-vagrant
===============

Use [Vagrant](https://www.vagrantup.com/) to get the [OpenAid](http://openaiddistro.org/) Drupal distribution up and running quickly.
Uses shell provisioner for simplicity. Drush is also used to setup the install.

### Requirements
* Vagrant
    * Known to work with Vagrant 1.7.4 on OS X El Capitan, 
but should theoretically work on any system that runs Vagrant 1.7x
* Vagrant uses [VirtualBox](http://www.virtualbox.org/)
    * Known to work with VirtualBox 5.0.4
* The Vagrantfile specifies (and uses) Debian Jessie (8.x) and that's all that's been tested.
However, Debian Wheezy (7.x) may also work, though the `Require all granted` line 
of the bootstrap.sh script may need to be removed for Apache to start.

### Basic Usage

        $ git clone git://github.com/rothwerx/openaid-vagrant.git
        $ cd openaid-vagrant
        $ vim Vagrantfile bootstrap.sh  # Configure as desired or leave default
        $ vagrant up
        ...Grab some coffee while the installation runs...
        # Log into the web interface at http://localhost:8080/user/login
        #   using the admin account created by drush. The password
        #   should be in the red text in the last few lines of the 
        #   output from running `vagrant up`
        $ vagrant ssh

Site source will be available for development locally at `openaid-vagrant/openaid`, or within the box at `/var/www/html`
