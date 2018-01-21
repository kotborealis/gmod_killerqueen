AddCSLuaFile()

print "======================="
print "[lc] Sheer Heart Attack"
print "======================="

local npc_sha_detonate_radius = CreateConVar("npc_sha_detonate_radius", 50, bit.bor(FCVAR_GAMEDLL, FCVAR_DEMO, FCVAR_SERVER_CAN_EXECUTE),
                                                "When there's target within this radius around SHA, bomb will be triggered")
local npc_sha_explosion_radius = CreateConVar("npc_sha_explosion_radius", 10, bit.bor(FCVAR_GAMEDLL, FCVAR_DEMO, FCVAR_SERVER_CAN_EXECUTE),
                                                "SHA's explosion radius")
local npc_sha_move_speed = CreateConVar("npc_sha_move_speed", 500, bit.bor(FCVAR_GAMEDLL, FCVAR_DEMO, FCVAR_SERVER_CAN_EXECUTE),
                                                "SHA's move speed")
local npc_sha_target_players = CreateConVar("npc_sha_target_players", 1, bit.bor(FCVAR_GAMEDLL, FCVAR_DEMO, FCVAR_SERVER_CAN_EXECUTE),
                                                "Target players?")

local npc_sha_model_scale = CreateConVar("npc_sha_model_scale", 2, bit.bor(FCVAR_GAMEDLL, FCVAR_DEMO, FCVAR_SERVER_CAN_EXECUTE),
                                                "SHA's model scale")

local npc_sha_sound_spawn = CreateConVar("npc_sha_sound_spawn", 1, bit.bor(FCVAR_GAMEDLL, FCVAR_DEMO, FCVAR_SERVER_CAN_EXECUTE),
                                                "Enable `Sheer Heart Attack` sound on NPC spawn")
local npc_sha_sound_kotchio_miro = CreateConVar("npc_sha_sound_kotchio_miro", 1, bit.bor(FCVAR_GAMEDLL, FCVAR_DEMO, FCVAR_SERVER_CAN_EXECUTE),
                                                "Enable `Kotchio Miro` sound")


ENT.Base 			= "base_nextbot"
ENT.Spawnable		= true

function IsValidShearHeartAttackTarget(entity)
	return entity and entity:IsValid() and (entity:IsOnFire() or ((entity:IsPlayer() or entity:IsNPC()) and entity:Health() > 0))
end

function ENT:Initialize()
	self.__sheerheartattack = 57005

	self:SetModel("models/sha.mdl")
	self:SetMaterial("materials/model/sha/ntxr000.vmt")
	self:SetModelScale(npc_sha_model_scale:GetInt())

	if npc_sha_sound_spawn:GetBool() then
		self:EmitSound("sha.mp3")
	end
 
    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:Wake()
    end
end

function ENT:SetEnemy( ent )
	self.Enemy = ent
end

function ENT:GetEnemy()
	return self.Enemy
end

function ENT:SetOwner( ent )
	self.sha__Owner = ent
end

function ENT:GetOwner()
	return self.sha__Owner
end

function ENT:HaveEnemy()
	return IsValidShearHeartAttackTarget(self:GetEnemy()) or self:FindEnemy()
end

function ENT:FindEnemy()
	local _ents = ents.GetAll()
	local human = nil
	local object = nil


	for k, v in pairs(_ents) do
		if (v:IsPlayer() or v:IsNPC()) and v:Health() > 0 then
			if !human or self:GetPos():Distance(v:GetPos()) < self:GetPos():Distance(human:GetPos()) then
				if not (v:IsPlayer() and not npc_sha_target_players:GetBool()) and self:GetOwner() != v and self != v then
					human = v
				end
			end
		elseif v:IsOnFire() then
			if !object or self:GetPos():Distance(v:GetPos()) < self:GetPos():Distance(object:GetPos()) then
				object = v
			end
		end
	end

	if object then
		self:SetEnemy(object)
		if npc_sha_sound_kotchio_miro:GetBool() then
			self:EmitSound("kotchio_miro.mp3")
		end
		return true
	elseif human then
		self:SetEnemy(human)
		if npc_sha_sound_kotchio_miro:GetBool() then
			self:EmitSound("kotchio_miro.mp3")
		end
		return true
	end

	self:SetEnemy(nil)
	return false
end

function ENT:RunBehaviour()
	while true do
		if self:HaveEnemy() then
			self.loco:FaceTowards(self:GetEnemy():GetPos())
			self:StartActivity(ACT_RUN)
			self.loco:SetDesiredSpeed(npc_sha_move_speed:GetInt())
			self.loco:SetAcceleration(900)
			self:ChaseEnemy()
			self.loco:SetAcceleration(400)
			self:StartActivity(ACT_IDLE)
		end
		coroutine.wait(0.5)
	end
end

function ENT:explodeTarget(target)
	local pos = target:GetPos()
	local target_dissolve = target:IsNPC() or target:IsPlayer()

	local explode = ents.Create("env_explosion")
	explode:SetPos(pos)
	explode:SetOwner(self)
	explode:Spawn()
	explode:SetKeyValue("iMagnitude", npc_sha_explosion_radius:GetInt())
	explode:Fire("Explode", 0, 0)

	if target_dissolve then 
		target:TakeDamage(self.__sheerheartattack, self, self) 
	else 
		timer.Simple(0.01, function() 
			if target:IsValid() then 
				target:Remove() 
			end
		end)
	end
end

function ENT:HandleStuck()
	if not SERVER then return end

	local _ents = ents.FindInSphere(self:GetPos(), npc_sha_detonate_radius:GetInt())
	local rm = nil

	for k, ent in pairs(_ents) do
		if !ent:IsWorld() and ent:GetCollisionGroup() ~= COLLISION_GROUP_DEBRIS and (not rm or self:GetPos():Distance(ent:GetPos()) < self:GetPos():Distance(rm:GetPos())) and ent != self and ent != self:GetOwner() then
			rm = ent
			break
		end
	end

	if rm then 
		self:explodeTarget(rm)
		self.loco:ClearStuck()
	end
end

function ENT:ChaseEnemy(options)
	local options = options or {}
	local path = Path("Follow")
	path:SetMinLookAheadDistance(options.lookahead or 300)
	path:SetGoalTolerance(options.tolerance or 20)
	path:Compute(self, self:GetEnemy():GetPos())

	if !path:IsValid() then return "failed" end

	while path:IsValid() and self:HaveEnemy() do
		if path:GetAge() > 0.1 then
			path:Compute(self, self:GetEnemy():GetPos())
		end
		
		path:Update(self)

		if self:GetPos():Distance(self:GetEnemy():GetPos()) < npc_sha_detonate_radius:GetInt() then
			self:explodeTarget(self:GetEnemy())
			self:SetEnemy(nil)
		end

		if self.loco:IsStuck() then
			self:HandleStuck()
			return "stuck"
		end

		coroutine.yield()
	end
	return "ok"
end

if SERVER then
	hook.Add("EntityTakeDamage", "SECONDARYBOMBKILLERQUEEN", function(entity, dmg)
		if dmg:GetInflictor().__sheerheartattack then
			dmg:SetDamageType(DMG_DISSOLVE)
		end
	end)
end