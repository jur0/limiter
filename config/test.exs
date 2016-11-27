use Mix.Config

config :limiter,
  storage: [{Limiter.Storage.ConCache, :limiter_con_cache},
            {Limiter.Storage.ConCache, :limiter_con_cache_small_ttl}]

config :limiter, :limiter_con_cache,
  ttl_check: 1_000

config :limiter, :limiter_con_cache_small_ttl,
  ttl_check: 100
