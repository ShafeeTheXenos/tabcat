# Tabcat-specific configs, such as PHI (Protected Health Information) level
#
# Configs are stored in a document with the ID "config" in the tabcat-data DB
# (this will eventually allow multiple data DBs with different configurations)

# for more info about PHI see:
# http://www.research.ucsf.edu/chr/HIPAA/chrHIPAAfaq.asp

@tabcat ?= {}
tabcat.config = {}

# DB where config doc is stored
DATA_DB = 'tabcat-data'

# so we don't have to type window.localStorage in functions
localStorage = @localStorage

# Helper for tabcat.config.get()
fixAndRememberConfig = (configDoc) ->
  # strip document fields; we just want the configs
  config = _.omit(configDoc, '_id', '_rev', 'type')

  config.PHI = !!config.PHI
  config.limitedPHI = config.PHI or !!config.limitedPHI

  # store locally. Remove _rev, since this is an offline document
  localStorage.config = JSON.stringify(config)

  return config


# Promise: get the current config, based on the "config" document
#
# Fields we will make sure are filled in the config doc returned:
#
# - PHI (boolean): do we allow full PHI? (e.g. name of the patient)
# - limitedPHI (boolean): do we allow Limited Dataset PHI? This allows us to
#   store dates, timestamps, city, state, and zipcode. Implied by "PHI".
#
# - _id: should always be "config"
# - type: should always be "config"
tabcat.config.get = _.once(->
  tabcat.couch.getDoc(DATA_DB, 'config').then(
    (configDoc) -> fixAndRememberConfig(configDoc),
    (xhr) -> switch xhr.status
      # network error
      when 0
        # if we're offline, use the config we last stored, if any
        $.Deferred().resolve(JSON.parse(localStorage.config ? '{}'))

      # config doesn't exist
      when 404
        $.Deferred().resolve(fixAndRememberConfig({}))

      # some other kind of error
      else xhr  # pass through failure
  )
)
