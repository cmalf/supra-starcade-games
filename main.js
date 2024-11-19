const axios = require('axios');
const config = require('./config');

const color = {
    green: '\x1b[32m',
    blue: '\x1b[34m',
    yellow: '\x1b[33m',
    underLine: '\x1b[4m',
    reset: '\x1b[0m'
};

function x(x1, x2, xdata) {
    return xdata.split(x1)[1].split(x2)[0];
}

async function timer(clk) {
    const ti = Date.now() + clk * 1000;
    while (true) {
        process.stdout.write("\r                        \r");
        const res = Math.floor((ti - Date.now()) / 1000);
        if (res < 1) {
            break;
        }
        process.stdout.write(new Date(res * 1000).toISOString().substr(11, 8));
        await new Promise(resolve => setTimeout(resolve, 1000));
    }
}


const url = "https://prod-supra-bff-blastoff.services.supra.com/graphql";

const headers = {
    "User-Agent": config.UserAgent,
    "authorization": config.auth,
    "content-type": "application/json",
    "accept-language": "id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7,zh-TW;q=0.6,zh;q=0.5",
    "accept": "*/*",
};

const json = {
    operationName: 'getstarcadeUserStaticsData',
    variables: {
        input: {
            isManualFetch: true,
        },
    },
    query: 'query getstarcadeUserStaticsData($input: starcadeUserStatisticInput) { starcadeUserStaticsData(input: $input) }',
};

const json2 = {
    operationName: 'getTotalDiceGamePlay',
    variables: {
        input: {
            gameId: 2,
        },
    },
    query: 'query getTotalDiceGamePlay($input: totalAttemptLeftInput!) { totalUserAttemptLeftCount(input: $input) }',
};

const json3 = {
    operationName: "User",
    variables: {
        auth0Id: config.auth0
    },
    query: "query User($auth0Id: String) { user(auth0Id: $auth0Id) { id auth0Id refCode referralUrl email firstName lastName username phoneNumber country isBanned bannedReason kycStatus totalPoints totalTokens isPhoneNotificationsEnabled isGpcEnabled supraTokenPrice isEmailVerified rankName manualReview createdAt discordId twitterId emailVerificationCode verificationEmailSentAt walletAddress stakingPreference __typename } }"
};

const headers2 = {
    "accept": "text/x-component",
    "accept-language": "id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7,zh-TW;q=0.6,zh;q=0.5",
    "content-type": "text/plain;charset=UTF-8",
    "next-action": "9b70c85f59b333b810f4d606cd4a1e3958b87b79",
    "User-Agent": config.UserAgent,
};

async function fetchData() {
    try {
        const response1 = await axios.post(url, json, { headers });
        console.log(color.underLine + color.blue + `\nInfo Total Tx starcade\n` + color.reset);
        console.log(response1.data.data.starcadeUserStaticsData);

        const response2 = await axios.post(url, json2, { headers });
        console.log(color.underLine + color.blue + `\nDice Vision LeftCount\n` + color.reset);
        console.log("totalUserAttemptLeftCount:", response2.data.data.totalUserAttemptLeftCount);

        const response3 = await axios.post(url, json3, { headers });
        console.log(color.underLine + color.blue + `\nData User Supra Account\n` + color.reset);
        console.log(response3.data.data.user);
        const wallet = response3.data.data.user.walletAddress;

        const uri = `https://testnet.suprascan.io/address/${wallet}/f?tab=addr-transaction`;
        const json4 = `[{ "hash": "${wallet}", "blockchainEnvironment": "testnet" }]`;

        const response4 = await axios.post(uri, json4, { headers: headers2 });
        console.log(color.underLine + color.blue + `\nInfo Wallet\n` + color.reset);
        const addressBasicInfo = response4.data;
        const netWorth = x('netWorth":"', '"', addressBasicInfo);
        const netWorthUsd = x('netWorthUsd":"', '"', addressBasicInfo);
        const valueChange = x('valueChange":"', '"', addressBasicInfo);
        const totalTransactions = x('totalTransactions":"', '"', addressBasicInfo);
        const sentTransactions = x('sentTransactions":"', '"', addressBasicInfo);
        const receivedTransactions = x('receivedTransactions":"', '"', addressBasicInfo);
        const sequenceNumber = x('sequenceNumber":"', '"', addressBasicInfo);
        const activityLevel = x('activityLevel":"', '"', addressBasicInfo);
        
        console.log({
            netWorth,
            netWorthUsd,
            valueChange,
            totalTransactions,
            sentTransactions,
            receivedTransactions,
            sequenceNumber,
            activityLevel
        });
        console.log(`\nAuto Update In:`+color.underLine+color.green); 
        await timer(config.CountDown);
        console.clear();
        fetchData();
    } catch (error) {
        console.error(error);
    }
}

console.clear();
fetchData();

