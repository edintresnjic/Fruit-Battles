local Weapon = require(script:WaitForChild("WeaponsObj"))

local WeaponsStorage = {
	Apple = Weapon.new("Apple", "Free", 15, "Throwable", 500, 1.5, 1),
	Banana = Weapon.new("Banana", 300, 20, "Throwable", 500, 1.5, 3),
	Watermelon = Weapon.new("Watermelon", 600, 30, "Throwable", 400, 2, 5),
	Lemon = Weapon.new("Lemon", 1250, 10, "Throwable", 650, 0.8, 8),
	Pumpkin = Weapon.new("Pumpkin", 2000, 30, "Throwable", 700, 2, 10),
	Grape = Weapon.new("Grape", 3000, 15, "Throwable", 600, 1, 13),
	Rokakaka = Weapon.new("Rokakaka", 5000, 25, "Throwable", 675, 2, 16),
	GomuGomuNoMi = Weapon.new("GomuGomuNoMi", 6500, 15, "Throwable", 650, 1, 20),
}

return WeaponsStorage
