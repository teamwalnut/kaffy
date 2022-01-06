const { readFileSync, writeFileSync } = require("fs");
const configFilePath = "./config/prod.exs";
const gitBranch = process.env.BRANCH_NAME;
let configFile = readFileSync(configFilePath).toString();
console.log(`config file before:\n${configFile}\n\n`);
console.log(`altering ${configFile}...`);
configFile = configFile.replace(
  /domain: \"api\.teamwalnut\.com\"/g,
  `domain: "${gitBranch}-api.teamwalnut.com"`
);
console.log(`env file after:\n${configFile}\n\n`);
writeFileSync(configFilePath, configFile);
