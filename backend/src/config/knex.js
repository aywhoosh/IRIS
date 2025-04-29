/**
 * Knex database client configuration for the IRIS backend
 */
const knexConfig = require('./database');

// Determine environment
const environment = process.env.NODE_ENV || 'development';

// Create knex instance
const knex = require('knex')(knexConfig[environment]);

module.exports = knex;
