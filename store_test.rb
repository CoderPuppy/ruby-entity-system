require File.expand_path("../lib/entity_system.rb", __FILE__)

module StoreTest
	include EntitySystem

	store = Store::LevelDB.new File.expand_path("../store_test.db", __FILE__)
	# store = Store::Memory.new
	store = Store::Cached.new store
	store["for:foo"] = "bar"
	store["for:fiz"] = "buz"
	store["rev:foo"] = "buz"
	store["rev:fiz"] = "bar"
	store.save
	store.unload
	# store.load gt: "for:", lt: "for:\177"
	# store.load
	p store["for:foo"]
	p store[gt: "for:", lt: "for:\177"].select{true}
	p store[gt: "rev:", lt: "rev:\177"].select{true}
	p store[gt: "", lt: "\177"].select{true}
	store.close
end