import {defineConfig,devices} from '@playwright/test';

export default defineConfig({
 testDir:'./tests/e2e',
 fullyParallel:false,
 workers:1,
 retries:process.env.CI?1:0,
 reporter:'line',
 outputDir:'test-output/playwright',
 use:{
  baseURL:'http://127.0.0.1:8790',
  trace:'retain-on-failure',
  screenshot:'only-on-failure'
 },
 projects:[{name:'chromium',use:{...devices['Desktop Chrome']}}],
 webServer:{
  command:'node dist/proof-server.js',
  url:'http://127.0.0.1:8790/proof-api/status',
  reuseExistingServer:false,
  timeout:30_000,
  env:{PROOF_PORT:'8790'}
 }
});
