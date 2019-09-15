require('babel-register');
require('babel-polyfill');
require('dotenv').config();

module.exports = {
    networks: {
        development: {
            host: "127.0.0.1",
            port: 7545,
            network_id: "*" // Match any network id
        },
    },
    contracts_directory: './contracts/',
    compilers: {
        solc: {
            optimizer: {
                enabled: true,
                runs: 200
            }
        }
    }
}