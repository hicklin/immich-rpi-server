```plantuml
cloud "cloud\nstorage"

rectangle "home network" #line.dashed {
	storage "external storage" {
		database "immich data"
		collections "raw assets"
	}
	
	node RPi {
		agent immich
	}

	actor "home pc"
}

actor "remote phone"
actor "remote admin"

RPi <-> "external storage" : USB

RPi <-- "remote admin" : tailscale

"external storage" --> "cloud\nstorage" : rclone/\nrustic
immich <--> "remote phone" : tailscale
immich <-> "home pc" : "IP:2283"
```
