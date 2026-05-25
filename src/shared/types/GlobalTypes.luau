export type function Partial(ty: type): type
	local result = types.copy(ty)
	for key, property in ty:properties() do
		if property.read then
			result:setreadproperty(key, types.unionof(property.read, types.singleton(nil)))
		end
		if property.write then
			result:setwriteproperty(key, types.unionof(property.write, types.singleton(nil)))
		end
	end
	return result
end

export type R15Character = Model & {
	HumanoidRootPart: Part & {
		RootRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		OriginalSize: Vector3Value,
		RootAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
	},
	LeftHand: MeshPart & {
		LeftHand: WrapTarget,
		LeftWristRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		LeftGripAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		OriginalSize: Vector3Value,
		LeftWrist: AnimationConstraint,
		LeftWristBallSocket: BallSocketConstraint,
	},
	RightHand: MeshPart & {
		RightHand: WrapTarget,
		RightWristRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		RightGripAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		OriginalSize: Vector3Value,
		RightWrist: AnimationConstraint,
		RightWristBallSocket: BallSocketConstraint,
	},
	LeftLowerArm: MeshPart & {
		LeftLowerArm: WrapTarget,
		LeftElbowRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		LeftWristRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		OriginalSize: Vector3Value,
		LeftElbow: AnimationConstraint,
		LeftElbowBallSocket: BallSocketConstraint,
	},
	RightLowerArm: MeshPart & {
		RightLowerArm: WrapTarget,
		RightElbowRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		RightWristRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		OriginalSize: Vector3Value,
		RightElbow: AnimationConstraint,
		RightElbowBallSocket: BallSocketConstraint,
	},
	LeftUpperArm: MeshPart & {
		LeftUpperArm: WrapTarget,
		LeftShoulderRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
			JointRotation: Attachment,
		},
		LeftElbowRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		LeftShoulderAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		OriginalSize: Vector3Value,
		LeftHandNoCollision: NoCollisionConstraint,
		LeftShoulder: AnimationConstraint,
		LeftShoulderBallSocket: BallSocketConstraint,
	},
	RightUpperArm: MeshPart & {
		RightUpperArm: WrapTarget,
		RightShoulderRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
			JointRotation: Attachment,
		},
		RightElbowRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		RightShoulderAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		OriginalSize: Vector3Value,
		RightHandNoCollision: NoCollisionConstraint,
		RightShoulder: AnimationConstraint,
		RightShoulderBallSocket: BallSocketConstraint,
	},
	LeftFoot: MeshPart & {
		LeftFoot: WrapTarget,
		LeftAnkleRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		LeftFootAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		OriginalSize: Vector3Value,
		LeftAnkle: AnimationConstraint,
		LeftAnkleBallSocket: BallSocketConstraint,
	},
	LeftLowerLeg: MeshPart & {
		LeftLowerLeg: WrapTarget,
		LeftKneeRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		LeftAnkleRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		OriginalSize: Vector3Value,
		LeftKnee: AnimationConstraint,
		LeftKneeBallSocket: BallSocketConstraint,
	},
	UpperTorso: MeshPart & {
		UpperTorso: WrapTarget,
		WaistRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		NeckRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		LeftShoulderRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
			JointRotation: Attachment,
		},
		RightShoulderRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
			JointRotation: Attachment,
		},
		BodyFrontAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		BodyBackAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		LeftCollarAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		NeckAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		RightCollarAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		OriginalSize: Vector3Value,
		HumanoidRootPartNoCollision: NoCollisionConstraint,
		RightUpperLegNoCollision: NoCollisionConstraint,
		LeftUpperLegNoCollision: NoCollisionConstraint,
		LeftLowerLegNoCollision: NoCollisionConstraint,
		RightLowerLegNoCollision: NoCollisionConstraint,
		LeftLowerArmNoCollision: NoCollisionConstraint,
		RightLowerArmNoCollision: NoCollisionConstraint,
		Waist: AnimationConstraint,
		WaistBallSocket: BallSocketConstraint,
	},
	LeftUpperLeg: MeshPart & {
		LeftUpperLeg: WrapTarget,
		LeftHipRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		LeftKneeRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		OriginalSize: Vector3Value,
		RightUpperLegNoCollision: NoCollisionConstraint,
		LeftFootNoCollision: NoCollisionConstraint,
		LeftHip: AnimationConstraint,
		LeftHipBallSocket: BallSocketConstraint,
	},
	RightFoot: MeshPart & {
		RightFoot: WrapTarget,
		RightAnkleRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		RightFootAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		OriginalSize: Vector3Value,
		RightAnkle: AnimationConstraint,
		RightAnkleBallSocket: BallSocketConstraint,
	},
	RightLowerLeg: MeshPart & {
		RightLowerLeg: WrapTarget,
		RightKneeRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		RightAnkleRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		OriginalSize: Vector3Value,
		RightKnee: AnimationConstraint,
		RightKneeBallSocket: BallSocketConstraint,
	},
	LowerTorso: MeshPart & {
		LowerTorso: WrapTarget,
		RootRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		WaistRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		LeftHipRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		RightHipRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		WaistBackAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		WaistCenterAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		WaistFrontAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		OriginalSize: Vector3Value,
		LeftUpperArmNoCollision: NoCollisionConstraint,
		RightUpperArmNoCollision: NoCollisionConstraint,
		LeftLowerLegNoCollision: NoCollisionConstraint,
		RightLowerLegNoCollision: NoCollisionConstraint,
		Root: AnimationConstraint,
	},
	RightUpperLeg: MeshPart & {
		RightUpperLeg: WrapTarget,
		RightHipRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		RightKneeRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		OriginalSize: Vector3Value,
		RightFootNoCollision: NoCollisionConstraint,
		RightHip: AnimationConstraint,
		RightHipBallSocket: BallSocketConstraint,
	},
	Humanoid: Humanoid & {
		Status: Status,
		Animator: Animator,
		BodyTypeScale: NumberValue,
		BodyProportionScale: NumberValue,
		BodyWidthScale: NumberValue,
		BodyHeightScale: NumberValue,
		BodyDepthScale: NumberValue,
		HeadScale: NumberValue,
		HumanoidDescription: HumanoidDescription,
	},
	Head: MeshPart & {
		FaceControls: FaceControls,
		Head: WrapTarget,
		FaceFrontAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		HatAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		HairAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		FaceCenterAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		NeckRigAttachment: Attachment & {
			OriginalPosition: Vector3Value,
		},
		OriginalSize: Vector3Value,
		HumanoidRootPartNoCollision: NoCollisionConstraint,
		LeftUpperArmNoCollision: NoCollisionConstraint,
		RightUpperArmNoCollision: NoCollisionConstraint,
		Neck: AnimationConstraint,
		NeckBallSocket: BallSocketConstraint,
	},
	Animate: LocalScript & {
		cheer: StringValue & {
			CheerAnim: Animation,
		},
		climb: StringValue & {
			ClimbAnim: Animation,
		},
		dance: StringValue & {
			Animation1: Animation & {
				Weight: NumberValue,
			},
			Animation2: Animation & {
				Weight: NumberValue,
			},
			Animation3: Animation & {
				Weight: NumberValue,
			},
		},
		dance2: StringValue & {
			Animation1: Animation & {
				Weight: NumberValue,
			},
			Animation2: Animation & {
				Weight: NumberValue,
			},
			Animation3: Animation & {
				Weight: NumberValue,
			},
		},
		dance3: StringValue & {
			Animation1: Animation & {
				Weight: NumberValue,
			},
			Animation2: Animation & {
				Weight: NumberValue,
			},
			Animation3: Animation & {
				Weight: NumberValue,
			},
		},
		fall: StringValue & {
			FallAnim: Animation,
		},
		idle: StringValue & {
			Animation1: Animation & {
				Weight: NumberValue,
			},
			Animation2: Animation & {
				Weight: NumberValue,
			},
		},
		jump: StringValue & {
			JumpAnim: Animation,
		},
		laugh: StringValue & {
			LaughAnim: Animation,
		},
		point: StringValue & {
			PointAnim: Animation,
		},
		sit: StringValue & {
			SitAnim: Animation,
		},
		toollunge: StringValue & {
			ToolLungeAnim: Animation,
		},
		toolnone: StringValue & {
			ToolNoneAnim: Animation,
		},
		toolslash: StringValue & {
			ToolSlashAnim: Animation,
		},
		wave: StringValue & {
			WaveAnim: Animation,
		},
		ScaleDampeningPercent: NumberValue,
		run: StringValue & {
			RunAnim: Animation,
		},
		swim: StringValue & {
			Swim: Animation,
		},
		swimidle: StringValue & {
			SwimIdle: Animation,
		},
		walk: StringValue & {
			WalkAnim: Animation,
		},
		PlayEmote: BindableFunction,
		mood: StringValue & {
			Animation1: Animation,
		},
	},
	["Body Colors"]: BodyColors,
}

return nil
