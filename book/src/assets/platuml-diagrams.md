# Plantuml diagrams

## Data flow diagram

```plantuml
rectangle "home network" {
	storage "encrypted external storage" as storage {
		database "immich\ndatabase" as db
		collections "immich\ndata" as data
    folder "secrets"
	}
	
	node RPi {
		agent immich
	}

	actor "home pc"
}

actor "remote phone"
actor "remote admin"

data -[hidden]right- db
db -[hidden]right- secrets

RPi <-left-> storage : USB
RPi <-- "remote admin" : tailscale

immich <--> "remote phone" : tailscale
immich <-> "home pc" : "immich.local:2283"

cloud "encrypted\ncloud\nstorage" as cloud
data --> cloud : rclone/\nrustic
```

## Exposed immich data flow diagram

```plantuml
@startuml
title Public Immich access via Tailscale Funnel

skinparam componentStyle rectangle
skinparam defaultTextAlignment center

' Actors
actor "User with\nvalid mTLS cert" as UserMTLS #lightgreen
actor "User without\nvalid mTLS cert" as UserNoMTLS #lightcoral

' Tailscale
cloud "Internet" {
  node "Tailscale Funnel" as Funnel {
    interface "TCP Forward" as TCPFwd #skyblue
  }
}

' Home Network
package "Home Network" {
  node "Raspberry Pi Server" as RPi {
    
    component "Caddy Reverse Proxy" as Caddy {
      portin " :8443 " as Port8443 #skyblue
      
      frame "Request Processing" #WhiteSmoke {
        storage "mTLS cert\nvalid?" as q1 #gold
        storage "Share API\npath?" as q2 #gold
        
        interface "Full Access" as allow #lightgreen
        interface "Share Only" as shareonly #orange
        interface "Block\n**403**" as block #lightcoral
      }
      
      portout " Proxy " as ProxyOut
    }
    
    component "Immich" as Immich #lightblue {
      portin " :2283 " as Port2283 #skyblue
    }
    
    component "fail2ban" as Fail2ban #lavender
  }
}

' Caddy internal flow
Port8443 -down-> q1 : ""
q1 -down-> allow : "✓ yes"
allow -down-> ProxyOut : ""

q1 -right-> q2 : "✗ no"
q2 -down-> shareonly : "✓ yes"
shareonly -down-> ProxyOut : ""

q2 -right-> block : "✗ no"

' External connections
UserMTLS --> TCPFwd : "HTTPS +\nmTLS cert"
UserNoMTLS --> TCPFwd : "HTTPS"

TCPFwd --> Port8443 : "TCP\nForward"

ProxyOut --> Port2283 : "Allowed\nrequests"

Caddy -right-> Fail2ban : "logs"
Fail2ban .up.> Caddy : "  ban rules  "
Immich -[hidden]right- Fail2ban

note right of Fail2ban
  **Monitors for:**
  • Failed auth attempts
  • API scanning patterns
  • Excessive requests
  • Blocks abusive IPs
end note

@enduml
```