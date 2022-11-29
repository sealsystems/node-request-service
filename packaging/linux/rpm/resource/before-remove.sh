#!/bin/bash
#
# Ordering (according to https://www.golinuxhub.com/2018/05/how-to-execute-script-at-pre-post-preun-postun-spec-file-rpm/)
# The scriptlets in %pre and %post are respectively run before and after a package is installed.
# The scriptlets %preun and %postun are run before and after a package is uninstalled.
# On upgrade, the scripts are run in the following order:
#
# 1. %pre of new package
# 2. (package install)
# 3. %post of new package     -> after-install.sh
# 4. %preun of old package    -> before-remove.sh
# 5. (removal of old package)
# 6. %postun of old package

# Stop service
systemctl stop "<%= name %>"

# Only on uninstall
if [ "$1" = "0" ]; then
  # Remove systemd config
  systemctl disable "<%= name %>"
  rm -f "/usr/lib/systemd/system/<%= name %>.service"

  # Remove sudoers config
  rm -f "/etc/sudoers.d/<%= name %>"

  # Remove config file for Envconsul if not altered
  # Will be restored by next starting service, see start.sh.
  if diff "${RPM_INSTALL_PREFIX}/<%= name %>/envconsul.json.template" "${RPM_INSTALL_PREFIX}/etc/envconsul.json" > /dev/null; then
    rm -f "${RPM_INSTALL_PREFIX}/etc/envconsul.json"
  fi

  <%= before-remove-include %>
fi
