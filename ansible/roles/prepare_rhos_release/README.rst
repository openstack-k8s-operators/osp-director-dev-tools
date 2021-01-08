Prepare rhos-release

This role can be used to install/update rhos-release package
and configure rhos-release repositories using rhos-release binary.

The installation of rhos-release happens unconditionally to ensure
latest version of that package is on the test system.

This role is intended to run once before other roles which
are expecting the OSP repositories to be configured.

**Role Variables**

.. zuul:rolevar:: rhos_release_bin
   :default: '/usr/bin/rhos-release'

   Path to the rhos-release binary.

.. zuul:rolevar:: rhos_release_args
   :default: Undefined

   Arguments passed to the rhos-release binary.
   If no arguments are passed, the role is skipped.

.. zuul:rolevar:: disable_repositories
   :default: Undefined

   List of repositories to disable after rhos-release is ran.
   If no arguments are passed, the task is skipped.

.. zuul:rolevar:: enable_repositories
   :default: Undefined

   List of repositories to enable after rhos-release is ran.
   If no arguments are passed, the task is skipped.
