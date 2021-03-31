import subprocess
import os
import sys
import yaml

from time import sleep
from volttron.platform import set_home, certs
from slogger import get_logger

slogger = get_logger("setup-platform", "setup")

# The environment variables must be set or we have big issues
VOLTTRON_ROOT = os.environ["VOLTTRON_ROOT"]
VOLTTRON_HOME = os.environ["VOLTTRON_HOME"]
RMQ_HOME = os.environ["RMQ_HOME"]
VOLTTRON_CMD = "volttron"
VOLTTRON_CTL_CMD = "volttron-ctl"
VOLTTRON_CFG_CMD = "vcfg"
INSTALL_PATH = "{}/scripts/install-agent.py".format(VOLTTRON_ROOT)
KEYSTORES = os.path.join(VOLTTRON_HOME, "keystores")

if not VOLTTRON_HOME:
    VOLTTRON_HOME = "/home/volttron/.volttron"


def get_platform_config_path():
    platform_config = None
    if "PLATFORM_CONFIG" in os.environ and os.environ["PLATFORM_CONFIG"]:
        platform_config = os.environ["PLATFORM_CONFIG"]
    elif os.path.isfile("/platform_config.yml"):
        platform_config = "/platform_config.yml"

    # Stop processing if platform config hasn't been specified
    if platform_config is None:
        sys.stderr.write("No platform configuration specified.")
        sys.exit(0)

    return platform_config


def get_platform_configurations(platform_config_path):
    with open(platform_config_path) as cin:
        config = yaml.safe_load(cin)
        agents = config["agents"]
        platform_cfg = config["config"]

    print("Platform instance name set to: {}".format(platform_cfg.get("instance-name")))

    return config, agents, platform_cfg


def configure_platform(platform_cfg):
    # install web dependencies if web-enabled
    bind_web_address = platform_cfg.get("bind-web-address", None)
    if bind_web_address is not None:
        print(f"Platform bind web address set to: {bind_web_address}")
        from requirements import extras_require as extras

        web_plt_pack = extras.get("web", None)
        install_cmd = ["pip3", "install"]
        install_cmd.extend(web_plt_pack)
        if install_cmd is not None:
            print(f"Installing packages for web platform: {web_plt_pack}")
            subprocess.check_call(install_cmd)

    # Create the main volttron config file
    if not os.path.isdir(VOLTTRON_HOME):
        os.makedirs(VOLTTRON_HOME)

    cfg_path = os.path.join(VOLTTRON_HOME, "config")
    if not os.path.exists(cfg_path):
        if len(platform_cfg) > 0:
            with open(os.path.join(cfg_path), "w") as fout:
                fout.write("[volttron]\n")
                for key, value in platform_cfg.items():
                    fout.write("{}={}\n".format(key.strip(), value.strip()))


def install_agents(agents):
    need_to_install = {}

    print("Available agents that are needing to be setup/installed")
    print(agents)

    # TODO Fix so that the agents identities are consulted.
    for identity, specs in agents.items():
        path_to_keystore = os.path.join(KEYSTORES, identity)
        if not os.path.exists(path_to_keystore):
            need_to_install[identity] = specs

    # if we need to do installs then we haven't setup this at all.
    if need_to_install:
        # Start volttron first because we can't install anything without it
        proc = subprocess.Popen([VOLTTRON_CMD, "-vv"])
        assert proc is not None
        sleep(20)

        envcpy = os.environ.copy()
        for identity, spec in need_to_install.items():
            slogger.info("Processing identity: {}\n".format(identity))
            sys.stdout.write("Processing identity: {}\n".format(identity))
            agent_cfg = None
            if "source" not in spec:
                sys.stderr.write("Invalid source for identity: {}\n".format(identity))
                continue

            if "config" in spec and spec["config"]:
                agent_cfg = os.path.abspath(
                    os.path.expandvars(os.path.expanduser(spec["config"]))
                )
                if not os.path.exists(agent_cfg):
                    sys.stderr.write(
                        "Invalid config ({}) for agent id identity: {}\n".format(
                            agent_cfg, identity
                        )
                    )
                    continue

            agent_source = os.path.expandvars(os.path.expanduser(spec["source"]))

            if not os.path.exists(agent_source):
                sys.stderr.write(
                    "Invalid agent source ({}) for agent id identity: {}\n".format(
                        agent_source, identity
                    )
                )
                continue

            # grab the priority from the system config file
            priority = spec.get("priority", "50")
            tag = spec.get("tag", "some agent tag")

            install_cmd = ["python3", INSTALL_PATH]
            install_cmd.extend(["--agent-source", agent_source])
            install_cmd.extend(["--vip-identity", identity])
            # install_cmd.extend(["--start", "--priority", priority])
            # install_cmd.extend(["--agent-start-time", "30"])
            install_cmd.append("--force")
            install_cmd.extend(["--tag", tag])
            if agent_cfg:
                install_cmd.extend(["--config", agent_cfg])

            # This allows install agent to ignore the fact that we aren't running
            # form a virtual environment.
            envcpy["IGNORE_ENV_CHECK"] = "1"
            subprocess.check_call(install_cmd, env=envcpy)

            if "config_store" in spec:
                sys.stdout.write("Processing config_store entries")
                for key, entry in spec["config_store"].items():
                    if "file" not in entry or not entry["file"]:
                        sys.stderr.write(
                            "Invalid config store entry file must be specified for {}".format(
                                key
                            )
                        )
                        continue
                    entry_file = os.path.expandvars(os.path.expanduser(entry["file"]))

                    if not os.path.exists(entry_file):
                        sys.stderr.write(
                            "Invalid config store file does not exist {}".format(
                                entry_file
                            )
                        )
                        continue

                    entry_cmd = [
                        VOLTTRON_CTL_CMD,
                        "config",
                        "store",
                        identity,
                        key,
                        entry_file,
                    ]
                    if "type" in entry:
                        entry_cmd.append(entry["type"])

                    subprocess.check_call(entry_cmd)


def final_platform_configurations():
    auth_add = ["vctl", "auth", "add", "--credentials", "/.*/"]
    slogger.info(f"Adding * creds to auth. {auth_add}")
    subprocess.call(auth_add)

    sys.stdout.write("\n**************************************************\n")
    sys.stdout.write("SHUTTING DOWN FROM SETUP-PLATFORM.PY\n")
    sys.stdout.write("**************************************************\n")
    subprocess.call(["vctl", "shutdown", "--platform"])

    sleep(5)
    sys.exit(0)


if __name__ == "__main__":
    set_home(VOLTTRON_HOME)
    platform_config_path = get_platform_config_path()
    config, agents, platform_cfg = get_platform_configurations(platform_config_path)
    configure_platform(platform_cfg)
    install_agents(agents)
    final_platform_configurations()
