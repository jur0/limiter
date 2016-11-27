use Mix.Config

config :limiter,
  storage: [{Limiter.Storage.ConCache, :limiter_con_cache}]

config :limiter, :limiter_con_cache,
  ttl_check: 1_000
