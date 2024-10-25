import requests

base_url = "http://51.138.34.104/"

user_id = "8c827311-011b-4799-8ae9-004b51f4580c"  # OMG LEAKED  :O

data = [    # Av. Dr. Lourenço Peixinho - Oita B STOP
    {
      "bus_id": "d7b15589-69a5-488f-be0e-bbdf37cee4f7",
      "route_id": "295bdf2a-7e85-40b0-b91a-6433c0106db1",
      "route_number": 11,
      "arrival_time": "1970-01-01T07:58:00"
    },
    {
      "bus_id": "6487e6cc-4010-4729-b556-7ba571bbf3bd",
      "route_id": "295bdf2a-7e85-40b0-b91a-6433c0106db1",
      "route_number": 11,
      "arrival_time": "1970-01-01T08:23:00"
    },
    {
      "bus_id": "5e82a5d3-10f3-443a-81aa-d7a05bd25c25",
      "route_id": "295bdf2a-7e85-40b0-b91a-6433c0106db1",
      "route_number": 11,
      "arrival_time": "1970-01-01T08:53:00"
    },
    {
      "bus_id": "3dd97ff1-296b-4aa0-9299-5a665693584f",
      "route_id": "e0d6abfd-d20a-4e03-8f19-239318d5b9a1",
      "route_number": 5,
      "arrival_time": "1970-01-01T07:12:30"
    },
    {
      "bus_id": "e19c7f84-2f3d-464c-80c8-e2fc3c0fc8fa",
      "route_id": "e0d6abfd-d20a-4e03-8f19-239318d5b9a1",
      "route_number": 5,
      "arrival_time": "1970-01-01T08:02:30"
    },
    {
      "bus_id": "6d604af7-c66d-4c87-ad85-ce1e6b983fa8",
      "route_id": "e0d6abfd-d20a-4e03-8f19-239318d5b9a1",
      "route_number": 5,
      "arrival_time": "1970-01-01T09:17:30"
    }
  ]

buses = []
# get just bus_id
for i in range(len(data)):
    buses.append(data[i]["bus_id"])

for i in range(len(buses)):
    response = requests.post(base_url + "travel/register", json={"user_id": user_id, "bus_id": buses[i]})
    print(response.json())

response = requests.get(base_url + "travel")

print(response.json())

