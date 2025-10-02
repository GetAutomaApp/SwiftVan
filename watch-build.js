const { exec } = require("child_process");

const buildCmd = "npm run build:van:example";

let serverProcess;

function startServer() {
  if (serverProcess) serverProcess.kill();
  serverProcess = exec("npx serve . -l 8080");
  serverProcess.stdout.pipe(process.stdout);
  serverProcess.stderr.pipe(process.stderr);
}

function buildAndServe() {
  const build = exec(buildCmd);
  build.stdout.pipe(process.stdout);
  build.stderr.pipe(process.stderr);

  build.on("exit", (code) => {
    console.log(`Build finished with code ${code}`);
    startServer();
  });
}

buildAndServe();
