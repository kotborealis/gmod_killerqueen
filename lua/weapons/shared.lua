AddCSLuaFile()

print "======================"
print "[lc] Killer Queen SWEP"
print "======================"

KQ_set_radius = 200
KQ_trigger_radius = 100
KQ_explosion_radius = "10"
KQ_delay = 0.75

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

function SWEP:Initialize()
	self.__killerqueen = 57005
end

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
			if distance <= KQ_set_radius then
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
				local target = bomb[self.Owner];
				local target_dissolve = bomb[self.Owner]:IsNPC() or bomb[self.Owner]:IsPlayer();

				bomb[self.Owner] = nil;

				if not target_dissolve then
					for key, entity in pairs(ents.FindInSphere(pos, KQ_trigger_radius)) do
						local _ = entity:IsNPC() or entity:IsPlayer()
						if _ then
							pos = entity:GetPos()
							target = entity
							target_dissolve = true
							break
						end
					end
				end

				local explode = ents.Create("env_explosion")
				explode:SetPos(pos)
				explode:SetOwner(self.Owner)
				explode:Spawn()
				explode:SetKeyValue("iMagnitude", KQ_explosion_radius)

				timer.Simple(KQ_delay, function() 
					if target_dissolve then 
						target:TakeDamage(self.__killerqueen, self.Owner, self) 
					else 
						timer.Simple(0.01, function() 
							if target:IsValid() then 
								target:Remove() 
							end
						end)
					end

					explode:Fire("Explode", 0, 0) 
				end)
			end
		end
	end
end

if SERVER then
	hook.Add("EntityTakeDamage", "PRIMARYBOMBKILLERQUEEN", function(entity, dmg)
		if dmg:GetInflictor().__killerqueen then
			dmg:SetDamageType(DMG_DISSOLVE)
		end
	end)
end