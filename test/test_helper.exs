ExUnit.start()

# Start the Registry for LineCounterServer tests
Registry.start_link(keys: :unique, name: CodeChanges.ServerRegistry)
