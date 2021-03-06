AddCSLuaFile()

print "======================"
print "[lc] Killer Queen SWEP"
print "======================"

local swep_kq_charge_radius = CreateConVar("swep_kq_charge_radius", 200, bit.bor(FCVAR_GAMEDLL, FCVAR_DEMO, FCVAR_SERVER_CAN_EXECUTE),
                                                "Radius in which you can charge entity as bomb")
local swep_kq_trigger_radius = CreateConVar("swep_kq_trigger_radius", 100, bit.bor(FCVAR_GAMEDLL, FCVAR_DEMO, FCVAR_SERVER_CAN_EXECUTE),
                                                "Radius in which charged object will trigger player/npc detonation")
local swep_kq_explosion_radius = CreateConVar("swep_kq_explosion_radius", 10, bit.bor(FCVAR_GAMEDLL, FCVAR_DEMO, FCVAR_SERVER_CAN_EXECUTE),
												"Explosion radius")
local swep_kq_delay = CreateConVar("swep_kq_delay", 0.75, bit.bor(FCVAR_GAMEDLL, FCVAR_DEMO, FCVAR_SERVER_CAN_EXECUTE),
												"Delay between trigger (*click* sound) and explosion")

local swep_kq_target_owner = CreateConVar("swep_kq_target_owner", 0, bit.bor(FCVAR_GAMEDLL, FCVAR_DEMO, FCVAR_SERVER_CAN_EXECUTE),
												"Enable bomb to detonate it's owner")

local swep_kq_sha_admin_only = CreateConVar("swep_kq_sha_admin_only", 1, bit.bor(FCVAR_GAMEDLL, FCVAR_DEMO, FCVAR_SERVER_CAN_EXECUTE),
												"Restrict SHA to admins only")

local swep_kq_sound_deploy = CreateConVar("swep_kq_sound_deploy", 1, bit.bor(FCVAR_GAMEDLL, FCVAR_DEMO, FCVAR_SERVER_CAN_EXECUTE),
												"Enable `Killer Queen` sound on deploy")
local swep_kq_sound_charge = CreateConVar("swep_kq_sound_charge", 1, bit.bor(FCVAR_GAMEDLL, FCVAR_DEMO, FCVAR_SERVER_CAN_EXECUTE),
												"Enable `Ichi no bakudan` sound on charge")
local swep_kq_sound_trigger = CreateConVar("swep_kq_sound_trigger", 1, bit.bor(FCVAR_GAMEDLL, FCVAR_DEMO, FCVAR_SERVER_CAN_EXECUTE),
												"Enable *click* sound on trigger")

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

SWEP.ViewModel = "models/weapons/v_hands.mdl"
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

bomb = {}
sha = {}
btd = {}

function SWEP:Initialize()
	self:SetWeaponHoldType("magic")
	self.__killerqueen = 57005
	bomb[self.Owner] = nil
end

function SWEP:Deploy()
	if swep_kq_sound_deploy:GetBool() then
		self.Owner:EmitSound("killer_queen.mp3")
	end
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
			if distance <= swep_kq_charge_radius:GetInt() then
				if SERVER then self.Owner:ChatPrint("Killer Queen: Primary Bomb") end
				bomb[self.Owner] = entity
				if swep_kq_sound_charge:GetBool() then
					self.Owner:EmitSound("primary_bomb.mp3")
				end
			end
		end
	else
		if !bomb[self.Owner]:IsValid() then
			bomb[self.Owner] = nil
		elseif SERVER then 
			self.Owner:ChatPrint("*click*")
			if swep_kq_sound_trigger:GetBool() then
				self.Owner:EmitSound("click.mp3")
			end

			local target = bomb[self.Owner];
			local target_dissolve = bomb[self.Owner]:IsNPC() or bomb[self.Owner]:IsPlayer();

			bomb[self.Owner] = nil;

			timer.Simple(swep_kq_delay:GetFloat(), function() 
				if not target_dissolve then
					for key, entity in pairs(ents.FindInSphere(target:GetPos(), swep_kq_trigger_radius:GetInt())) do
						local _ = entity:IsNPC() or entity:IsPlayer()

						if not swep_kq_target_owner:GetBool() then
							_ = _ and self.Owner != entity
						end

						if _ and entity:IsValid() and entity:Health() > 0 then
							pos = entity:GetPos()
							target = entity
							target_dissolve = true
							break
						end
					end
				end

				local explode = ents.Create("env_explosion")
				explode:SetOwner(self.Owner)
				explode:SetKeyValue("iMagnitude", swep_kq_explosion_radius:GetInt())
				explode:Spawn()
				explode:SetPos(target:GetPos())
				explode:Fire("Explode", 0, 0)
				
				if target_dissolve then 
					target:TakeDamage(self.__killerqueen, self.Owner, self)
				else 
					timer.Simple(0.05, function() 
						if target:IsValid() then 
							target:Remove() 
						end
					end)
				end
			end)
		end
	end
end

function SWEP:SecondaryAttack()
	if not self.Owner:IsAdmin() and swep_kq_sha_admin_only:GetBool() then
		if SERVER then self.Owner:ChatPrint("Only admins can use Sheer Heart Attack") end
		return
	end

	if sha[self.Owner] then
		for key, entity in pairs(ents.GetAll()) do
			if entity == sha[self.Owner] then
				sha[self.Owner] = nil
				entity:Remove()
				return
			end
		end

		sha[self.Owner] = nil
	end

	local trace = util.TraceLine({
		start = self.Owner:EyePos(),
		endpos = self.Owner:EyePos() + self.Owner:EyeAngles():Forward() * 100000,
		filter = {self.Owner}
	})

	if SERVER then
		sha[self.Owner] = ents.Create("npc_sheer_heart_attack")
		sha[self.Owner]:SetPos(trace.HitPos)
		sha[self.Owner]:Spawn()
		sha[self.Owner]:SetOwner(self.Owner)
	end
end

if SERVER then
	hook.Add("EntityTakeDamage", "PRIMARYBOMBKILLERQUEEN", function(entity, dmg)
		if dmg:GetInflictor().__killerqueen then
			dmg:SetDamageType(DMG_DISSOLVE)
		end
	end)
end