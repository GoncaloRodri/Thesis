# 🎓 Computer Science Integrated Master's Thesis
## 🔒 Use of Differential Privacy for Unobservable Privacy-Preserved Communication

## 📁 Folder Structure
```
.
├── report              => 📄 Thesis report in LaTeX format
├── testing             => 🧪 All testing tools and configurations delevoped for the thesis
│   ├── configuration   -> ⚙️ Configuration files for testing tools
│   ├── docker          -> 🐳 Dockerfiles and related files for containerized testing
│   ├── logs            -> 📋 Logs generated during testing
│   ├── scripts         -> 📝 Scripts for running tests
├── tor                 => 🧅 Modified Tor source code 

```

## 🚀 Getting Started
Clone the repository
```bash
git clone https://github.com/GoncaloRodri/Thesis.git 
```

Initialize the submodules
```bash
git submodule init
git submodule update
```

This might fail if you don't have access to the private [Differential-Privacy-Tor](https://gitlab.torproject.org/GoncaloRodri/differential-privacy-tor) repository. In that case, you can clone any other Tor version that you want to use:
```bash
# Inside the Thesis folder, run: 
git clone <repository-url> tor 
```

### Dependencies
To launch the testing tools, you need to have Docker and Docker Compose installed. For that, please follow the instructions on the [Docker installation page](https://docs.docker.com/get-docker/) and [Docker Compose installation page](https://docs.docker.com/compose/install/).

```bash
apt install -y python3 python3-pip yq jq
```

## 🧪 Testing Tools
The testing tools are located in the `testing` folder. This folder contains all the necessary files to run tests, analyze results, and plot graphs. 

### ⚙️ Configuration Files
There are several configuration files across the `testing` folder, each serving a different purpose:
- `config.yaml` in `testing/tester/` folder: This file is used by the tester to configure the tests. For more information, refer to the Tester documentation.
- `testing/configuration/` folder: Contains configuration files for launching and configuring the Tor relays, clients and containers. For more information, refer to the Tor Configuration documentation.

### 🛠️ Helper Scripts
To easily run the project, you can use the provided 'run' bash script. This script contains the following commands:
```
./run [r | run]     => ▶️ Runs the tester acordingly with the configuration file "config.yaml", present in the "testing/scripts/tester/" folder.
./run [b | build]   => 🔨 Builds the docker image "dptor_node" using the Dockerfile present in the "testing/docker/" folder.
./run [a | analyze] => 📊 Analyzes the logs present in the "testing/logs/" folder, using the script "analyzer.py" present in the "testing/scripts/analyzer/" folder. Places the results in the "testing/results/" folder.
./run [p | plot]    => 📈 Plots the results of the tests, using the data present in the "testing/results/" folder. Places the plots in the "testing/plots/figures/" folder.
```

## 🧅 Tor

This work focuses on the use of differential privacy and mathematical distributions to provide unobservable privacy-preserved communication. To achieve this, we modified the Tor source code to implement a differential private packet padding cells (referred as *dummy*) and a scheduler that extends the previous working schedulers, such as KIST and Vanilla, to inject random jitter conditions based on mathematical distributions to generate such randomness.

This solution tries to respect and maintain the original Tor design, while adding the necessary modifications to provide differential privacy. The solution is designed to be modular and extensible, allowing for future improvements and adaptations. To do so, we created 2 new schedulers (`PRIV_KIST` and `PRIV_Vanilla`) that implement the jitter mechanisms, and modified the `relay.c` file to handle the differential private packet padding cells.

The jitter is implemented using mathematical distributions, such as Exponential, Gaussian, Laplace, Normal and Poisson. This is introduced in the network by delaying (or not) the retransmission of packets, which is done by the scheduler.

The differential private packet padding cells mechanism uses a randomized response mechanism to decide to create and enqueue a dummy cell. This is triggered every time a cell is received and processed by the relay.

Both the jitter and the differential private packet padding cells solutions are designed to be configurable, allowing the user to set the parameters for the differential privacy budget (epsilon), the dummy traffic rate, and the jitter values (minimum, maximum and target).

You may find the solution in the [Differential-Privacy-Tor](https://gitlab.torproject.org/GoncaloRodri/differential-privacy-tor) repository. If you cannot access it, feel free to contact me.

### ⚙️ Configuration

As previously mentioned, the Tor configuration files are located in the `testing/configuration/` folder. This folder has the following structure:
```
testing/configuration/
├── nodes/                  => 🗂️ Contains the configuration files for the Tor nodes
│   ├── authority/          -> 🗂️ Authority directory configuration
│   ├── client/             -> 🗂️ Client configuration
│   ├── exit/               -> 🗂️ Exit node configuration
│  *├── exit1/              -> 🗂️ Special exit node configuration
│   ├── relay/              -> 🗂️ Relay configuration
│  *├── relay1/             -> 🗂️ Special relay node configuration
│  *├── relay2/             -> 🗂️ Special relay node configuration
│
├── tor.authority.torrc     => 📝 Authority directory configurations
├── tor.client.torrc        => 📝 Client configurations
├── tor.common.torrc        => 📝 Common configurations
├── tor.exit.torrc          => 📝 Exit node configurations
├── tor.relay.torrc         => 📝 Relay node configurations
├── tor.non-exit.torrc      => 📝 Non-exit relay configurations
├── tor.hs.torrc            => 📝 Hidden service configurations
```

(*The `exit1`, `relay1` and `relay2` folders are used for testing purposes and contain specific configurations for the minimal Tor network used in the experiments. You may only need to use the abstract `exit`, `relay` and `authority` folders, which contain the common configurations for the Tor nodes.*)

Each *.torrc* file contains the necessary configurations related with the Tor node type. Each node type then imports the needed configurations.
All types of nodes (authority, client, exit, relay) import the `tor.common.torrc` file. All relays import the `tor.relay.torrc` file, except the clients. Also, the exit nodes are the only ones that import the `tor.exit.torrc` file, while the others import the `tor.non-exit.torrc` file. The authority directories are the only ones that import the `tor.authority.torrc` file, while the clients import the `tor.client.torrc` file.

These experiments are designed to run only one authority directory. In order to run multiple authority directories, you must have a different configuration folder for each authority directory, with different predefined fingerprint files. Also, you must modify the `tor.common.torrc` file the following line for each authority directory:
```bash
DirAuthority <name_of_node> orport=9001 v3ident=<crypto/keys/authority_certificate.fingerprint> <docker_ip_address>:9030 <fingerprint>
```

## 🔬 The Tester

The tester automates Tor network experiments and performance measurements. This script launches an experimental and containerized Tor network, using Docker Compose, and tests the performance and/or unobservability by executing HTTP requests through the Tor network and measuring both metrics and logs.

The `docker-compose.yml` contains the configuration for the Docker containers, including the Tor relays and clients. You can modify this file to your need and add more relays or clients as needed. 

Remember that a minimal tor network requires at least one authority directory and 3 relays, of which, at least one must be an exit.

### 📋 `monitor.sh`
Main script that loads configuration, iterates through experiments, and executes them with specified parameters.

### 📂 Helper Scripts:
- **🛠️ `utils.sh`**: Logging utilities and configuration parsing
- **🏃 `run.sh`**: Orchestrates experiment flow, Docker cleanup, and Tor network setup
- **🔨 `build.sh`**: Docker image building and Tor network bootstrapping
- **👥 `clients.sh`**: Manages concurrent client instances and timeouts
- **🌐 `request.sh`**: Executes HTTP requests via Tor SOCKS5 proxy and measures performance

### ⚙️ Configuration

To configure the tester, you must edit the `config.yaml` file located in the `testing/scripts/tester/` folder. The file contains the following structure:
```yaml
config:
    absolute_path: <path to your Thesis folder>         # Absolute path for the project
    repeat: uint                                        # Number of times to repeat each experiment
    copy_logs: boolean                                  # Whether to copy logs after experiments
    logs_dir: <relative_path_to_logs>                   # Directory for storing logs
    docker_dir:
        <relative_path_to_docker_folder>                # Directory containing Docker files
    data_dir: <relative_path_to_analyzer>               # Directory for experiment data
    configuration_dir:                                  # Directory for Tor configuration files
        <relative_path_to_configuration_folder>        
    top_website_path:
        <relative_path_to_list_of_websites>             # Path to list of websites for testing

experiments:
    - name: string
        end_test_at: uint                           # Test duration in seconds
        tcpdump_mode: bool                          # Enable/disable network packet capture
        filesize: string[]                          # File sizes to test (in bytes)
        tor:                                        # Tor-specific differential privacy parameter
            dummy: double                           # Dummy traffic rate
            max_jitter: uint                        # Maximum jitter value  
            min_jitter: uint                        # Minimum jitter value
            target_jitter: uint                     # Target jitter value
            dp_epsilon: double                      # Privacy budget (epsilon value)
            scheduler:                              # Tor scheduler type
                <"PRIV_KIST" | "PRIV_Vanilla" | "KIST" | "Vanilla">
            dp_distribution:                        # Differential privacy distribution type
                <"EXPONENTIAL" | "GAUSSIAN" | "LAPLACE" | "NORMAL" | "POISSON">
        clients:                                    # Client configuration
            bulk_clients: uint
            web_clients: uint
            top_web_clients: uint



combinations:
    tcpdump: boolean                                # Enable/disable network packet capture
    filesize: string[]                              # File sizes to test (in bytes)
    end_test_at: uint                               # Test duration in seconds
    clients:                                        # Client configuration [bulk, web, top_web]
        - tuple[uint, uint, uint]                   # [bulk clients, web clients, top website clients]
        - ...
        - ...
    tor:                                            # Tor-specific differential privacy parameters
        dummy: double[]                             # Dummy traffic rates
        max_jitter: uint[]                          # Maximum jitter values
        min_jitter: uint[]                          # Minimum jitter values  
        target_jitter: uint[]                       # Target jitter values
        dp_distribution:                            # Differential privacy distribution type
            <"EXPONENTIAL" | "GAUSSIAN" | "LAPLACE" | "NORMAL" | "POISSON">[]                
        dp_epsilon: double[]                        # Privacy budget (epsilon values)
        scheduler:                                  # Tor scheduler type
            <"PRIV_KIST" | "PRIV_Vanilla" | "KIST" | "Vanilla">[]                    
```

#### 📝 Configuration Sections:
- **🔧 `config`**: Basic paths and experiment settings
- **▶️ `experiments`**: Singular experiment configuration
- **🎯 `combinations`**: Multiple experiment that runs all combinations of values



