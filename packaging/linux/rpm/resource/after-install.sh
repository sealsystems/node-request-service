# Do not add shebang!
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

addSealUser() {
  if ! getent group seal > /dev/null 2>&1; then
    groupadd -r seal
  fi
  if ! getent passwd seal > /dev/null 2>&1; then
    useradd --system --home-dir "/var/lib/seal" --create-home --shell "/bin/false" --gid seal seal
  fi
}

chownSeal()
{
  chown seal:seal "${1}"
  # Note: X sets executable bit only for directories or if it is already set.
  chmod ug=rwX,o=rX "${1}"

  if [ -d "${1}" ]; then
    # Ignore error if directory is empty
    chown seal:seal "${1}"/* >/dev/null 2>&1 || true
    chmod ug=rwX,o=rX "${1}"/* >/dev/null 2>&1 || true
  fi
}

mkSealDir()
{
  mkdir -p "${1}"
  chownSeal "${1}"
}

addSealUser

mkSealDir "/var/log/seal/"
mkSealDir "${RPM_INSTALL_PREFIX}/etc"

# Stop and disable service if this is an update
if [ "${1}" = "2" ]; then
  systemctl stop "<%= name %>" || true
  systemctl disable "<%= name %>"
fi

# Replace installation prefix within service
sed -i "s|/opt/seal/|${RPM_INSTALL_PREFIX}/|g" "${RPM_INSTALL_PREFIX}/<%= name %>/<%= name %>.service"
sed -i "s|/opt/seal/|${RPM_INSTALL_PREFIX}/|g" "${RPM_INSTALL_PREFIX}/<%= name %>/start.sh"

# Remove service file from old location to clean up obsolete versions
rm -f "/lib/systemd/system/<%= name %>.service"
rm -f "/etc/systemd/system/<%= name %>.service"
# Remove old service file and copy new one
rm -f "/usr/lib/systemd/system/<%= name %>.service"
cp "${RPM_INSTALL_PREFIX}/<%= name %>/<%= name %>.service" "/usr/lib/systemd/system/<%= name %>.service"

# Add service to sudoers
if [ -d "/etc/sudoers.d" ]; then
  rm -f "/etc/sudoers.d/<%= name %>"
  cp "${RPM_INSTALL_PREFIX}/<%= name %>/sudoers" "/etc/sudoers.d/<%= name %>"
fi

# Copy pre-installed tls certificate into config dir if it does not exist already
if [ ! -e "${RPM_INSTALL_PREFIX}/etc/tls" ]; then
  cp -r "${RPM_INSTALL_PREFIX}/<%= name %>/tls" "${RPM_INSTALL_PREFIX}/etc"
  chownSeal "${RPM_INSTALL_PREFIX}/etc/tls"
  chmod o-rwx "${RPM_INSTALL_PREFIX}"/etc/tls/*key*.pem
fi

# Setcap not always installed on SuSE Linux
if which setcap >/dev/null 2>&1; then
  setcap 'cap_net_bind_service=+ep' "${RPM_INSTALL_PREFIX}/<%= name %>/<%= setcap-executable %>"
fi

<%= after-install-include %>

# Enable service
systemctl daemon-reload
systemctl enable "<%= name %>" || true
