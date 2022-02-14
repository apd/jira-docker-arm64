# -------------------------------------------------------------------------------------
# Common bootstrapping for support scripts (get app details: home directory, PID, etc.)
# -------------------------------------------------------------------------------------


# Set up Java utils
JCMD="${JAVA_HOME}/bin/jcmd"

# Set up app info
APP_NAME="$(set | grep '_INSTALL_DIR' | awk -F'_' '{print $1}')"

# Get value of <app>_INSTALL_DIR
function get_app_install_dir {
    local APP_INSTALL_DIR="$(set | grep ${APP_NAME}_INSTALL_DIR | awk -F'=' '{print $2}')"
    echo ${APP_INSTALL_DIR}
}

# Get value of <app>_HOME
function get_app_home {
    local APP_HOME="$(set | grep ${APP_NAME}_HOME | awk -F'=' '{print $2}')"
    echo ${APP_HOME}
}


# Get app PID
case "${APP_NAME}" in
    BITBUCKET )
        BOOTSTRAP_PROC="com.atlassian.bitbucket.internal.launcher.BitbucketServerLauncher"
        ;;
    * )
        BOOTSTRAP_PROC="org.apache.catalina.startup.Bootstrap"
        ;;
esac

APP_PID=$(${JCMD} | grep "${BOOTSTRAP_PROC}" | awk '{print $1}')



# Set valid getopt options
function set_valid_options {
    OPTS=$(getopt -o "$1" --long "$2" -n 'parse-options' -- "$@")
    if [ $? != 0 ]; then
        echo "Failed parsing options." >&2
        exit 1
    fi
    eval set -- "$OPTS"
}


# Run command(s)
function run_as_runuser {
    if [ $(id -u) = 0 ]; then
        su "${RUN_USER}" -c '"$@"' -- argv0 "$@"
    else
        $@
    fi
}
