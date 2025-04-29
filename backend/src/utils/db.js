const knex = require('knex');
const config = require('../config/database');

const env = process.env.NODE_ENV || 'development';
const knexInstance = knex(config[env]);

module.exports = knexInstance;