require('dotenv').config()

var config = {};

config.NET_ID = process.env.NET_ID || "";
config.PASSWORD = process.env.PASSWORD || "";

module.exports = config;