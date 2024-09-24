#!/bin/bash

# Commands run from kubernetes from a single container, after a new release deployment.
# Source: https://www.bounteous.com/insights/2020/03/11/automate-drupal-deployments/

# Maintenance mode activation
/app/bin/drush --root /app/web/ -y state:set system.maintenance_mode 1

# Running Drupal’s update process should be the very first thing to run.
# Do not clear any caches before running updates! This may seem counter-intuitive,
# but it is requisite to certain types of updates like converting field definitions.
# We put ---no-cache-clear flag as updatedb command clear the caches only if there are
# post updates commands
/app/bin/drush --root /app/web/ -y updatedb --no-cache-clear

# Here we clear caches to ensure all the updates are going correctly
/app/bin/drush --root /app/web/ cache:rebuild

# You’ll notice the first config:import line has two pipe characters.
# There is an issue with the config import process where if a module is installed
# and configuration entities are being created for that module it may fail to
# create the config entities because of missing dependencies.
/app/bin/drush --root /app/web/ -y config:import || /app/bin/drush --root /app/web/ -y config:import

# Assuming the first config import completes successfully, we need to run the
# config import a second time. The first config import may include changes to
# the behavior of config import, such as config ignore or config split. We must
# run config import a second time to ensure those changes take effect.
/app/bin/drush --root /app/web/ -y config:import

# At this point, we are done with the critical parts of deployment. Now, we
# disable the maintenance window to allow regular use of the site again.
/app/bin/drush --root /app/web/ -y state:set system.maintenance_mode 0

# Last, we clear caches to ensure all caches are clear from any caches generated
# while the maintenance mode was enabled.
/app/bin/drush --root /app/web/ cache:rebuild
