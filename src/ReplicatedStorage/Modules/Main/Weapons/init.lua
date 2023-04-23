local Weapon = require(script:WaitForChild("WeaponsObj"))

local WeaponsStorage = {
	Apple = Weapon.new("Apple", "Free", 15, "Throwable", 500, 1.5, 1),
	Banana = Weapon.new("Banana", 1000, 20, "Throwable", 500, 1.5, 3),
	Watermelon = Weapon.new("Watermelon", 2000, 30, "Throwable", 400, 2, 5),
	Lemon = Weapon.new("Lemon", 2500, 10, "Throwable", 650, 0.8, 8),
	Pumpkin = Weapon.new("Pumpkin", 5000, 30, "Throwable", 700, 2, 10),
	Grape = Weapon.new("Grape", 10000, 15, "Throwable", 600, 1, 20),
	Rokakaka = Weapon.new("Rokakaka", 15000, 25, "Throwable", 675, 2, 25),
	GomuGomuNoMi = Weapon.new("GomuGomuNoMi", 20000, 15, "Throwable", 650, 1, 30),
}

return WeaponsStorage
