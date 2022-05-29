require('dotenv').config()
var config = require("./config.js");
const puppeteer = require('puppeteer');

(async () => {
    const browser = await puppeteer.launch({
        // headless: false,
        args: ['--window-size=500,900'],
        defaultViewport: null
        });
    const page = await browser.newPage();
    await page.goto('https://sso.ucsb.edu/cas/login?service=https%3a%2f%2fstudenthealthoc.sa.ucsb.edu%2f', {waitUntil: 'networkidle2'});
    
    await page.type("#username", config.NET_ID);
    await page.type("#password", config.PASSWORD);

    await page.click('input[type="submit"]'),
    await page.waitForSelector('#cmdStudentDualAuthentication.btn.btn-primary.btn-lg'),

    console.log("Logged in!");
    await page.$eval('input[name=cmdStudentDualAuthentication]', el => el.click()),
    await page.waitForSelector('#showQuarantineBadge.btn.btn-primary'),
    
    console.log("Navigated to health portal home page");
    await page.$eval('button#showQuarantineBadge.btn.btn-primary', el => el.click()),
    await page.waitForSelector('#patImage'),
    await delay(100);

    console.log("Covid badge loaded!");
    await page.screenshot({ path: 'example.png' }),
    await browser.close();
})();

const delay = ms => new Promise(resolve => setTimeout(resolve, ms))