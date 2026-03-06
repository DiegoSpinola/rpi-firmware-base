# Alloy Template Project

The Alloy Template Project is a starting point for projects using the Alloy framework. This template includes a sample `alloy-dummy-helloworld` dependency that fetches a basic webserver with a "Hello World" message and the Alloy logo.

## Getting Started

### Prerequisites

Before using this template, ensure that you have the following installed:

- [Docker](https://www.docker.com/get-started)
- [Alloy framework](https://github.com/igma-company/alloy)

### Installation

1. Clone this repository:

   ```bash
   git clone git@github.com:igma-company/alloy-template.git
   cd alloy-template
   ```

2. Start the Alloy environment by running:

   ```bash
   ./alloy.sh
   ```

   This script will download the Alloy Docker image if needed and run it in interactive mode. The pulled image mounts your project workspace folder into the Alloy container.

3. Fetch dependencies using the alloy clone command (this recursively fetches all dependencies):

   ```bash
   alloy clone
   ```

### Using the scripts

Once inside the Alloy environment, you can use the available scripts:

1. **Build**: Run `build.sh` to build the `demo-webserver` Docker image using the included `docker-compose.yml` file.

   ```bash
   bash build.sh
   ```

2. **Run**: Run `run.sh` to start the `demo-webserver`. It will be available on `http://[HOST_IP]:8080`.

   ```bash
   bash run.sh
   ```

3. **Deploy**: Run `deploy.sh` to execute the deploy process. Note that this script only outputs a message for now. You need to implement custom deployment logic based on your project requirements.

   ```bash
   bash deploy.sh
   ```

   Don't forget to replace the mock deployment message with your custom deployment logic.

## Project Structure

```
alloy-template/
├── alloy.sh            # Start Alloy environment (run with ./alloy.sh)
├── build.sh            # Build Docker images (run with bash build.sh)
├── run.sh              # Run services (run with bash run.sh)
├── deploy.sh           # Deploy to registry (run with bash deploy.sh)
├── docker-compose.yml  # Service definitions
├── .config             # Alloy dependencies
├── .gitignore          # Git ignore patterns
└── demo/               # Demo webserver (via alloy clone)
```

> **Note on script execution:** Only `alloy.sh` has the executable bit set and can be run directly with `./alloy.sh`. This is because it runs on the user's host machine where we cannot assume which shell is configured (bash, zsh, fish, etc.). All other scripts run inside the Alloy environment where bash is guaranteed, so they should be invoked with `bash script.sh`.

## Contributing

Should you find any issues or have suggestions, feel free to open an issue or submit a pull request. We appreciate your contributions to improve the Alloy Template Project.
