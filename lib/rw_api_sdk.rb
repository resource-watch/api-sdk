# coding: utf-8
#
# Many years later, as he faced the firing squad, Colonel
# Aureliano Buendía was to remember that distant afternoon when
# his father took him to discover Rails.
#
# I'm trying to offer some of the Rails interface
# for its models, so we'll need active_record
require 'active_record'
# And also select pieces of active_support
require 'active_support/core_ext'
# Also, the usual http and json stuff
require 'net/http'
require 'json'
# This gem will handle API calls
require 'httparty'
# And some code modularization is in order
# Some Rails magic is required.
require 'rw_api_sdk/attr_changeable_methods'
# And the actual API interfacing will be living in separate classes
require 'rw_api_sdk/vocabulary'
require 'rw_api_sdk/widget'
require 'rw_api_sdk/layer'
require 'rw_api_sdk/metadata'
require 'rw_api_sdk/dataset'
# Needed for change-tracking in hash values
require 'rw_api_sdk/dataset_service'
# Needed for change-tracking in hash values
require 'colorize'
# Color in puts. To be replaced with a proper logger

