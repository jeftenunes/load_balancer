import Config

config :load_balancer,
  servers: ["http://0.0.0.0:4002", "http://0.0.0.0:4001"],
  health_check_interval_in_seconds: 5,
  health_check_endpoint: "/home/health"
