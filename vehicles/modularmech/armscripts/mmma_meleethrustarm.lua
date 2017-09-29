require "/vehicles/modularmech/armscripts/base.lua"

MeleeThrustArm = MechArm:extend()

function MeleeThrustArm:init()
  self.state = FSM:new()
end

function MeleeThrustArm:update(dt)
  if self.state.state then
    self.state:update()
  end

  if not self.state.state then
    if self.fireTriggered then
      self.state:set(self.windupState, self)
    end
  end

  if self.state.state then
    self.bobLocked = true
  else
    animator.rotateTransformationGroup(self.armName, -45, self.shoulderOffset)
    animator.setAnimationState(self.armName, "idle")
    self.bobLocked = false
  end
end

function MeleeThrustArm:windupState()
  animator.setAnimationState(self.armName, "windup")

  local stateTimer = self.windupTime
  while stateTimer > 0 do
    animator.rotateTransformationGroup(self.armName, self.aimAngle - self.windupAngleAdjust, self.shoulderOffset)
    stateTimer = stateTimer - script.updateDt()
    coroutine.yield()
  end

  self.state:set(self.fireState, self, self.windupExtend, self.fireExtend, false)
end

function MeleeThrustArm:fireState(fromReach, toReach, allowCombo)
  animator.playSound(self.armName .. "Fire")

  local stateTimer = self.fireTime
  local projectileSpawnTime = stateTimer - self.swingTime
  local fireWasTriggered = false
  while stateTimer > 0 do
    fireWasTriggered = fireWasTriggered or self.fireTriggered

    local thrustRatio = math.min(1, (self.fireTime - stateTimer) / self.swingTime)
    local currentExtend = util.lerp(thrustRatio, fromReach, toReach)
    local thrustVector = vec2.withAngle(self.aimAngle - self.fireAngleAdjust, currentExtend)

    animator.rotateTransformationGroup(self.armName, self.aimAngle - self.fireAngleAdjust, self.shoulderOffset)

    animator.translateTransformationGroup(self.armName, {-thrustVector[2], thrustVector[1]})

    local dt = script.updateDt()
    if stateTimer > projectileSpawnTime and (stateTimer - projectileSpawnTime) < dt then
      local travelDist = self.projectileBaseDistance - self.shoulderOffset[1] * self.facingDirection
      self.projectileParameters.speed = travelDist / self.projectileTimeToLive

      self:fire()
    end

    stateTimer = stateTimer - dt
    coroutine.yield()
  end

  if allowCombo and fireWasTriggered then
    self.state:set()
    self.state:set(self.fireState, self, self.fireExtend, self.comboFireExtend, false)
  else
    self.state:set(self.cooldownState, self)
  end
end

function MeleeThrustArm:cooldownState()
  animator.setAnimationState(self.armName, "winddown")

  local stateTimer = self.cooldownTime
  while stateTimer > 0 do
    animator.rotateTransformationGroup(self.armName, self.aimAngle - self.cooldownAngleAdjust, self.shoulderOffset)
    stateTimer = stateTimer - script.updateDt()
    coroutine.yield()
  end

  self.state:set()
end
