build:
	@mix compile

launch:
	@iex -S mix compile

run:
	@iex -S mix

manifest:
	@mix bonny.gen.manifest
