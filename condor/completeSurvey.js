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

    await page.click('input[type="submit"]');
    console.log("Waiting for Duo 2FA...")

    try {
        await page.waitForSelector('#cmdStudentDualAuthentication.btn.btn-primary.btn-lg', {timeout: 20000});
    } catch (err) {
        console.log("Duo request timed out!");
        process.exit(0);
    }

    console.log("Logged in!");
    await page.$eval('input[name=cmdStudentDualAuthentication]', el => el.click());
    await page.waitForSelector('#showQuarantineBadge.btn.btn-primary');
    
    console.log("Navigated to health portal home page");
    await page.goto('https://studenthealthoc.sa.ucsb.edu/Mvc/Patients/QuarantineSurvey', {waitUntil: 'networkidle2'});

    console.log("Covid survey loaded!");
    await page.$eval('a.btn.btn-lg.btn-success', el => el.click());
    await delay(100);

    await page.$eval('input[name="AllQuestions[0].AnswerID"][value="2"]', el => el.click());
    console.log("Q1 selected");
    await page.$eval('input[name="AllQuestions[1].AnswerID"][value="2"]', el => el.click());
    console.log("Q2 selected");
    await page.$eval('input[name="AllQuestions[2].AnswerID"][value="2"]', el => el.click());
    console.log("Q3 selected");
    await page.$eval('input[name="AllQuestions[3].AnswerID"][value="2"]', el => el.click());
    console.log("Q4 selected");
    await page.$eval('input[name="AllQuestions[4].AnswerID"][value="2"]', el => el.click());
    console.log("Q5 selected");
    await page.$eval('input.btn.btn-lg.btn-success', el => el.click()),
    console.log("Covid survey completed!");

    await delay(200);
    await page.screenshot({ path: 'example.png' }),
    await browser.close();
})();

const delay = ms => new Promise(resolve => setTimeout(resolve, ms))