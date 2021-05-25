# @summary This definition manages COPR (Cool Other Package Repo) repositories.
#
# @param repo [String]
#   Name of repository.
#
# @param ensure
#   Specifies if repo should be enabled, disabled or removed.
#
# @example Add a COPR repository:
#   ---
#   yum::copr { 'copart/restic':
#     ensure  => 'enabled',
#   }
#
define yum::copr (
  String                                 $repo   = $title,
  Enum['enabled', 'disabled', 'removed'] $ensure = 'enabled',
) {
  $prereq_plugin = $facts['package_provider'] ? {
    'yum'   => 'yum-plugin-copr',
    default => 'dnf-plugins-core',
  }
  ensure_packages([$prereq_plugin])

  if $facts['package_provider'] == 'yum' {
    $repo_name_part = regsubst($repo, '/', '-', 'G')
    case $ensure {
      'enabled': {
        exec { "yum -y copr enable ${repo}":
          path    => '/bin:/usr/bin:/sbin/:/usr/sbin',
          onlyif  => "test ! -e /etc/yum.repos.d/_copr_${repo_name_part}.repo",
          require => Package[$prereq_plugin],
        }
      }
      'disabled', 'removed': {
        exec { "yum -y copr disable ${repo}":
          path    => '/bin:/usr/bin:/sbin/:/usr/sbin',
          onlyif  => "test -e /etc/yum.repos.d/_copr_${repo_name_part}.repo",
          require => Package[$prereq_plugin],
        }
      }
      default: {
        fail("The value for ensure for `yum::copr` must be enabled, disabled or removed, but it is ${ensure}.")
      }
    }
  } else {
    case $ensure {
      'enabled': {
        exec { "dnf -y copr enable ${repo}":
          path    => '/bin:/usr/bin:/sbin/:/usr/sbin',
          unless  => "dnf copr list | egrep -q '${repo}\$'",
          require => Package[$prereq_plugin],
        }
      }
      'disabled': {
        # Need to enable first, then disable, to ensure it is added in disabled state.
        exec { "dnf -y copr enable ${repo}; dnf -y copr disable ${repo}":
          path    => '/bin:/usr/bin:/sbin/:/usr/sbin',
          unless  => "dnf copr list | egrep -q '${repo} (disabled)\$'",
          require => Package[$prereq_plugin],
        }
      }
      'removed': {
        exec { "dnf -y copr remove ${repo}":
          path    => '/bin:/usr/bin:/sbin/:/usr/sbin',
          unless  => "dnf copr list | egrep -q '${repo}'",
          require => Package[$prereq_plugin],
        }
      }
      default: {
        fail("The value for ensure for `yum::copr` must be enabled, disabled or removed, but it is ${ensure}.")
      }
    }
  }
}
