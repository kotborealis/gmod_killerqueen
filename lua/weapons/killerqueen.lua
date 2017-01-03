AddCSLuaFile()

print "======================"
print "[lc] Killer Queen SWEP"
print "======================"

swep_kq_charge_radius = CreateConVar("swep_kq_charge_radius", 200, bit.bor(FCVAR_GAMEDLL, FCVAR_DEMO, FCVAR_SERVER_CAN_EXECUTE),
                                                "Radius in which you can charge entity as bomb")
swep_kq_trigger_radius = CreateConVar("swep_kq_trigger_radius", 100, bit.bor(FCVAR_GAMEDLL, FCVAR_DEMO, FCVAR_SERVER_CAN_EXECUTE),
                                                "Radius in which charged object will trigger player/npc detonation")
swep_kq_explosion_radius = CreateConVar("swep_kq_explosion_radius", 10, bit.bor(FCVAR_GAMEDLL, FCVAR_DEMO, FCVAR_SERVER_CAN_EXECUTE),
												"Explosion radius")
swep_kq_delay = CreateConVar("swep_kq_delay", 0.75, bit.bor(FCVAR_GAMEDLL, FCVAR_DEMO, FCVAR_SERVER_CAN_EXECUTE),
												"Delay between trigger (*click* sound) and explosion")

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

function SWEP:Initialize()
	self.__killerqueen = 57005
	self.bomb = nil
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
	if !self.bomb then
		local entity = self.Owner:GetEyeTrace().Entity
		if entity and entity:IsValid() then
			local distance = self.Owner:GetPos():Distance(entity:GetPos())
			if distance <= swep_kq_charge_radius:GetInt() then
				if SERVER then self.Owner:ChatPrint("Killer Queen: Primary Bomb") end
				self.bomb = entity
			end
		end
	else
		if !self.bomb:IsValid() then
			self.bomb = nil
		else
			if SERVER then 
				self.Owner:ChatPrint("*click*")
				self.Owner:EmitSound("click.mp3")

				local target = self.bomb;
				local target_dissolve = self.bomb:IsNPC() or self.bomb:IsPlayer();

				self.bomb = nil;


				local explode = ents.Create("env_explosion")
				explode:SetOwner(self.Owner)
				explode:SetKeyValue("iMagnitude", swep_kq_explosion_radius:GetInt())

				timer.Simple(swep_kq_delay:GetFloat(), function() 
					if not target_dissolve then
						for key, entity in pairs(ents.FindInSphere(target:GetPos(), swep_kq_trigger_radius:GetInt())) do
							local _ = entity:IsNPC() or entity:IsPlayer()
							if _ and entity:IsValid() and entity:Health() > 0 then
								pos = entity:GetPos()
								target = entity
								target_dissolve = true
								break
							end
						end
					end

					if target_dissolve then 
						target:TakeDamage(self.__killerqueen, self.Owner, self) 
					else 
						timer.Simple(0.05, function() 
							if target:IsValid() then 
								target:Remove() 
							end
						end)
					end

					explode:Spawn()
					explode:SetPos(target:GetPos())
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