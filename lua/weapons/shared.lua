AddCSLuaFile()

print "======================"
print "[lc] Killer Queen SWEP"
print "======================"

SWEP.PrintName = "Killer Queen";
SWEP.Author = "Barreses"
SWEP.Purpose = "KILLER QUEEN"
SWEP.Category = "lc"

SWEP.Slot = 2;
SWEP.SlotPos = 4;
SWEP.DrawAmmo = false;
SWEP.DrawCrosshair = true;
SWEP.Weight = 5;
SWEP.AutoSwitchTo = false;
SWEP.AutoSwitchFrom = false;

SWEP.Spawnable = true

SWEP.ViewModel = ""
SWEP.WorldModel = ""

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
 
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Delay = 10

bomb = {};

function SWEP:Deploy()
	return true
end
 
function SWEP:Holster()
	return true
end
 
function SWEP:Think()
end

function SWEP:PrimaryAttack()
	if !bomb[self.Owner] then
		local entity = self.Owner:GetEyeTrace().Entity
		if entity and entity:IsValid() then
			local distance = self.Owner:GetPos():Distance(entity:GetPos())
			if distance <= 200 then
				if SERVER then self.Owner:ChatPrint("Killer Queen: Primary Bomb") end
				bomb[self.Owner] = entity
			end
		end
	else
		if !bomb[self.Owner]:IsValid() then
			bomb[self.Owner] = nil
		else
			if SERVER then 
				self.Owner:ChatPrint("*click*")
				self.Owner:EmitSound("click.mp3")

				local pos = bomb[self.Owner]:GetPos()
				bomb[self.Owner] = nil

				local explode = ents.Create("env_explosion")
				explode:SetPos(pos)
				explode:SetOwner(self.Owner)
				explode:Spawn()
				explode:SetKeyValue("iMagnitude", "100")
				explode:Fire("Explode", 0, 0)
			end
		end
	end
end