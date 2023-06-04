package keeper_test

import (
	"time"

	"github.com/merlin-network/black/v6/app"
	"github.com/merlin-network/black/v6/x/recovery/types"
	sdk "github.com/cosmos/cosmos-sdk/types"
	transfertypes "github.com/cosmos/ibc-go/v3/modules/apps/transfer/types"
	channeltypes "github.com/cosmos/ibc-go/v3/modules/core/04-channel/types"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

var _ = Describe("Recovery: Performing an IBC Transfer", Ordered, func() {
	coinblack := sdk.NewCoin("ablack", sdk.NewInt(10000))
	coinOsmo := sdk.NewCoin("uosmo", sdk.NewInt(10))
	coinAtom := sdk.NewCoin("uatom", sdk.NewInt(10))

	var (
		sender, receiver       string
		senderAcc, receiverAcc sdk.AccAddress
		timeout                uint64
		// claim                  claimtypes.ClaimsRecord
	)

	BeforeEach(func() {
		s.SetupTest()
	})

	Describe("from a non-authorized chain", func() {
		BeforeEach(func() {
			// params := "ablack"
			// params.AuthorizedChannels = []string{}

			sender = s.IBCOsmosisChain.SenderAccount.GetAddress().String()
			receiver = s.blackChain.SenderAccount.GetAddress().String()
			senderAcc = sdk.MustAccAddressFromBech32(sender)
			receiverAcc = sdk.MustAccAddressFromBech32(receiver)
		})
		It("should transfer and not recover tokens", func() {
			s.SendAndReceiveMessage(s.pathOsmosisblack, s.IBCOsmosisChain, "uosmo", 10, sender, receiver, 1)

			nativeblack := s.blackChain.App.(*app.Black).BankKeeper.GetBalance(s.blackChain.GetContext(), senderAcc, "ablack")
			Expect(nativeblack).To(Equal(coinblack))
			ibcOsmo := s.blackChain.App.(*app.Black).BankKeeper.GetBalance(s.blackChain.GetContext(), receiverAcc, uosmoIbcdenom)
			Expect(ibcOsmo).To(Equal(sdk.NewCoin(uosmoIbcdenom, coinOsmo.Amount)))
		})
	})

	Describe("from an authorized, non-EVM chain (e.g. Osmosis)", func() {
		Describe("to a different account on black (sender != recipient)", func() {
			BeforeEach(func() {
				sender = s.IBCOsmosisChain.SenderAccount.GetAddress().String()
				receiver = s.blackChain.SenderAccount.GetAddress().String()
				senderAcc = sdk.MustAccAddressFromBech32(sender)
				receiverAcc = sdk.MustAccAddressFromBech32(receiver)
			})

			It("should transfer and not recover tokens", func() {
				s.SendAndReceiveMessage(s.pathOsmosisblack, s.IBCOsmosisChain, "uosmo", 10, sender, receiver, 1)

				nativeblack := s.blackChain.App.(*app.Black).BankKeeper.GetBalance(s.blackChain.GetContext(), senderAcc, "ablack")
				Expect(nativeblack).To(Equal(coinblack))
				ibcOsmo := s.blackChain.App.(*app.Black).BankKeeper.GetBalance(s.blackChain.GetContext(), receiverAcc, uosmoIbcdenom)
				Expect(ibcOsmo).To(Equal(sdk.NewCoin(uosmoIbcdenom, coinOsmo.Amount)))
			})
		})

		Describe("to the sender's own eth_secp256k1 account on black (sender == recipient)", func() {
			BeforeEach(func() {
				sender = s.IBCOsmosisChain.SenderAccount.GetAddress().String()
				receiver = s.IBCOsmosisChain.SenderAccount.GetAddress().String()
				senderAcc = sdk.MustAccAddressFromBech32(sender)
				receiverAcc = sdk.MustAccAddressFromBech32(receiver)
			})

			Context("with disabled recovery parameter", func() {
				BeforeEach(func() {
					params := types.DefaultParams()
					params.EnableRecovery = false
					s.blackChain.App.(*app.Black).RecoveryKeeper.SetParams(s.blackChain.GetContext(), params)
				})

				It("should not transfer or recover tokens", func() {
					s.SendAndReceiveMessage(s.pathOsmosisblack, s.IBCOsmosisChain, coinOsmo.Denom, coinOsmo.Amount.Int64(), sender, receiver, 1)

					nativeblack := s.blackChain.App.(*app.Black).BankKeeper.GetBalance(s.blackChain.GetContext(), senderAcc, "ablack")
					Expect(nativeblack).To(Equal(coinblack))
					ibcOsmo := s.blackChain.App.(*app.Black).BankKeeper.GetBalance(s.blackChain.GetContext(), receiverAcc, uosmoIbcdenom)
					Expect(ibcOsmo).To(Equal(sdk.NewCoin(uosmoIbcdenom, coinOsmo.Amount)))
				})
			})

			Context("without a sender's claims record", func() {
				When("recipient has no ibc vouchers that originated from other chains", func() {
					It("should transfer and recover tokens", func() {
						// fmt.Println("Sender Account Numberc: ", s.IBCOsmosisChain.SenderAccount.GetAccountNumber())
						// fmt.Println("Sender Sequence: ", s.IBCOsmosisChain.SenderAccount.GetSequence())

						// ablack & ibc tokens that originated from the sender's chain
						s.SendAndReceiveMessage(s.pathOsmosisblack, s.IBCOsmosisChain, coinOsmo.Denom, coinOsmo.Amount.Int64(), sender, receiver, 1)
						timeout = uint64(s.blackChain.GetContext().BlockTime().Add(time.Hour * 4).Add(time.Second * -20).UnixNano())

						// Escrow before relaying packets
						balanceEscrow := s.blackChain.App.(*app.Black).BankKeeper.GetBalance(s.blackChain.GetContext(), transfertypes.GetEscrowAddress("transfer", "channel-0"), "ablack")
						Expect(balanceEscrow).To(Equal(coinblack))
						ibcOsmo := s.blackChain.App.(*app.Black).BankKeeper.GetBalance(s.blackChain.GetContext(), receiverAcc, uosmoIbcdenom)
						Expect(ibcOsmo.IsZero()).To(BeTrue())

						// Relay both packets that were sent in the ibc_callback
						err := s.pathOsmosisblack.RelayPacket(CreatePacket("10000", "ablack", sender, receiver, "transfer", "channel-0", "transfer", "channel-0", 1, timeout))
						s.Require().NoError(err)
						err = s.pathOsmosisblack.RelayPacket(CreatePacket("10", "transfer/channel-0/uosmo", sender, receiver, "transfer", "channel-0", "transfer", "channel-0", 2, timeout))
						s.Require().NoError(err)

						// Check that the ablack were recovered
						nativeblack := s.blackChain.App.(*app.Black).BankKeeper.GetBalance(s.blackChain.GetContext(), senderAcc, "ablack")
						Expect(nativeblack.IsZero()).To(BeTrue())
						ibcblack := s.IBCOsmosisChain.GetSimApp().BankKeeper.GetBalance(s.IBCOsmosisChain.GetContext(), receiverAcc, ablackIbcdenom)
						Expect(ibcblack).To(Equal(sdk.NewCoin(ablackIbcdenom, coinblack.Amount)))

						// Check that the uosmo were recovered
						ibcOsmo = s.blackChain.App.(*app.Black).BankKeeper.GetBalance(s.blackChain.GetContext(), receiverAcc, uosmoIbcdenom)
						Expect(ibcOsmo.IsZero()).To(BeTrue())
						nativeOsmo := s.IBCOsmosisChain.GetSimApp().BankKeeper.GetBalance(s.IBCOsmosisChain.GetContext(), receiverAcc, "uosmo")
						Expect(nativeOsmo).To(Equal(coinOsmo))
					})
				})

				// Do not recover uatom sent from Cosmos when performing recovery through IBC transfer from Osmosis
				When("recipient has additional ibc vouchers that originated from other chains", func() {
					BeforeEach(func() {
						params := types.DefaultParams()
						params.EnableRecovery = false
						s.blackChain.App.(*app.Black).RecoveryKeeper.SetParams(s.blackChain.GetContext(), params)

						// Send uatom from Cosmos to black
						s.SendAndReceiveMessage(s.pathCosmosblack, s.IBCCosmosChain, coinAtom.Denom, coinAtom.Amount.Int64(), s.IBCCosmosChain.SenderAccount.GetAddress().String(), receiver, 1)

						params.EnableRecovery = true
						s.blackChain.App.(*app.Black).RecoveryKeeper.SetParams(s.blackChain.GetContext(), params)
					})
					It("should not recover tokens that originated from other chains", func() {
						// Send uosmo from Osmosis to black
						s.SendAndReceiveMessage(s.pathOsmosisblack, s.IBCOsmosisChain, "uosmo", 10, sender, receiver, 1)

						// Relay both packets that were sent in the ibc_callback
						timeout := uint64(s.blackChain.GetContext().BlockTime().Add(time.Hour * 4).Add(time.Second * -20).UnixNano())
						err := s.pathOsmosisblack.RelayPacket(CreatePacket("10000", "ablack", sender, receiver, "transfer", "channel-0", "transfer", "channel-0", 1, timeout))
						s.Require().NoError(err)
						err = s.pathOsmosisblack.RelayPacket(CreatePacket("10", "transfer/channel-0/uosmo", sender, receiver, "transfer", "channel-0", "transfer", "channel-0", 2, timeout))
						s.Require().NoError(err)

						// ablack was recovered from user address
						nativeblack := s.blackChain.App.(*app.Black).BankKeeper.GetBalance(s.blackChain.GetContext(), senderAcc, "ablack")
						Expect(nativeblack.IsZero()).To(BeTrue())
						ibcblack := s.IBCOsmosisChain.GetSimApp().BankKeeper.GetBalance(s.IBCOsmosisChain.GetContext(), receiverAcc, ablackIbcdenom)
						Expect(ibcblack).To(Equal(sdk.NewCoin(ablackIbcdenom, coinblack.Amount)))

						// Check that the uosmo were retrieved
						ibcOsmo := s.blackChain.App.(*app.Black).BankKeeper.GetBalance(s.blackChain.GetContext(), receiverAcc, uosmoIbcdenom)
						Expect(ibcOsmo.IsZero()).To(BeTrue())
						nativeOsmo := s.IBCOsmosisChain.GetSimApp().BankKeeper.GetBalance(s.IBCOsmosisChain.GetContext(), receiverAcc, "uosmo")
						Expect(nativeOsmo).To(Equal(coinOsmo))

						// Check that the atoms were not retrieved
						ibcAtom := s.blackChain.App.(*app.Black).BankKeeper.GetBalance(s.blackChain.GetContext(), senderAcc, uatomIbcdenom)
						Expect(ibcAtom).To(Equal(sdk.NewCoin(uatomIbcdenom, coinAtom.Amount)))

						// Repeat transaction from Osmosis to black
						s.SendAndReceiveMessage(s.pathOsmosisblack, s.IBCOsmosisChain, "uosmo", 10, sender, receiver, 2)

						timeout = uint64(s.blackChain.GetContext().BlockTime().Add(time.Hour * 4).Add(time.Second * -20).UnixNano())
						err = s.pathOsmosisblack.RelayPacket(CreatePacket("10", "transfer/channel-0/uosmo", sender, receiver, "transfer", "channel-0", "transfer", "channel-0", 3, timeout))
						s.Require().NoError(err)

						// No further tokens recovered
						nativeblack = s.blackChain.App.(*app.Black).BankKeeper.GetBalance(s.blackChain.GetContext(), senderAcc, "ablack")
						Expect(nativeblack.IsZero()).To(BeTrue())
						ibcblack = s.IBCOsmosisChain.GetSimApp().BankKeeper.GetBalance(s.IBCOsmosisChain.GetContext(), receiverAcc, ablackIbcdenom)
						Expect(ibcblack).To(Equal(sdk.NewCoin(ablackIbcdenom, coinblack.Amount)))

						ibcOsmo = s.blackChain.App.(*app.Black).BankKeeper.GetBalance(s.blackChain.GetContext(), receiverAcc, uosmoIbcdenom)
						Expect(ibcOsmo.IsZero()).To(BeTrue())
						nativeOsmo = s.IBCOsmosisChain.GetSimApp().BankKeeper.GetBalance(s.IBCOsmosisChain.GetContext(), receiverAcc, "uosmo")
						Expect(nativeOsmo).To(Equal(coinOsmo))

						ibcAtom = s.blackChain.App.(*app.Black).BankKeeper.GetBalance(s.blackChain.GetContext(), senderAcc, uatomIbcdenom)
						Expect(ibcAtom).To(Equal(sdk.NewCoin(uatomIbcdenom, coinAtom.Amount)))
					})
				})

				// Recover ibc/uatom that was sent from Osmosis back to Osmosis
				When("recipient has additional non-native ibc vouchers that originated from senders chains", func() {
					BeforeEach(func() {
						params := types.DefaultParams()
						params.EnableRecovery = false
						s.blackChain.App.(*app.Black).RecoveryKeeper.SetParams(s.blackChain.GetContext(), params)

						s.SendAndReceiveMessage(s.pathOsmosisCosmos, s.IBCCosmosChain, coinAtom.Denom, coinAtom.Amount.Int64(), s.IBCCosmosChain.SenderAccount.GetAddress().String(), receiver, 1)

						// Send IBC transaction of 10 ibc/uatom
						transferMsg := transfertypes.NewMsgTransfer(s.pathOsmosisblack.EndpointA.ChannelConfig.PortID, s.pathOsmosisblack.EndpointA.ChannelID, sdk.NewCoin(uatomIbcdenom, sdk.NewInt(10)), sender, receiver, timeoutHeight, 0)
						_, err := s.IBCOsmosisChain.SendMsgs(transferMsg)
						s.Require().NoError(err) // message committed
						transfer := transfertypes.NewFungibleTokenPacketData("transfer/channel-1/uatom", "10", sender, receiver)
						packet := channeltypes.NewPacket(transfer.GetBytes(), 1, s.pathOsmosisblack.EndpointA.ChannelConfig.PortID, s.pathOsmosisblack.EndpointA.ChannelID, s.pathOsmosisblack.EndpointB.ChannelConfig.PortID, s.pathOsmosisblack.EndpointB.ChannelID, timeoutHeight, 0)
						// Receive message on the black side, and send ack
						err = s.pathOsmosisblack.RelayPacket(packet)
						s.Require().NoError(err)

						// Check that the ibc/uatom are available
						osmoIBCAtom := s.blackChain.App.(*app.Black).BankKeeper.GetBalance(s.blackChain.GetContext(), receiverAcc, uatomOsmoIbcdenom)
						s.Require().Equal(osmoIBCAtom.Amount, coinAtom.Amount)

						params.EnableRecovery = true
						s.blackChain.App.(*app.Black).RecoveryKeeper.SetParams(s.blackChain.GetContext(), params)
					})
					It("should not recover tokens that originated from other chains", func() {
						s.SendAndReceiveMessage(s.pathOsmosisblack, s.IBCOsmosisChain, "uosmo", 10, sender, receiver, 2)

						// Relay packets that were sent in the ibc_callback
						timeout := uint64(s.blackChain.GetContext().BlockTime().Add(time.Hour * 4).Add(time.Second * -20).UnixNano())
						err := s.pathOsmosisblack.RelayPacket(CreatePacket("10000", "ablack", sender, receiver, "transfer", "channel-0", "transfer", "channel-0", 1, timeout))
						s.Require().NoError(err)
						err = s.pathOsmosisblack.RelayPacket(CreatePacket("10", "transfer/channel-0/transfer/channel-1/uatom", sender, receiver, "transfer", "channel-0", "transfer", "channel-0", 2, timeout))
						s.Require().NoError(err)
						err = s.pathOsmosisblack.RelayPacket(CreatePacket("10", "transfer/channel-0/uosmo", sender, receiver, "transfer", "channel-0", "transfer", "channel-0", 3, timeout))
						s.Require().NoError(err)

						// ablack was recovered from user address
						nativeblack := s.blackChain.App.(*app.Black).BankKeeper.GetBalance(s.blackChain.GetContext(), senderAcc, "ablack")
						Expect(nativeblack.IsZero()).To(BeTrue())
						ibcblack := s.IBCOsmosisChain.GetSimApp().BankKeeper.GetBalance(s.IBCOsmosisChain.GetContext(), receiverAcc, ablackIbcdenom)
						Expect(ibcblack).To(Equal(sdk.NewCoin(ablackIbcdenom, coinblack.Amount)))

						// Check that the uosmo were recovered
						ibcOsmo := s.blackChain.App.(*app.Black).BankKeeper.GetBalance(s.blackChain.GetContext(), receiverAcc, uosmoIbcdenom)
						Expect(ibcOsmo.IsZero()).To(BeTrue())
						nativeOsmo := s.IBCOsmosisChain.GetSimApp().BankKeeper.GetBalance(s.IBCOsmosisChain.GetContext(), receiverAcc, "uosmo")
						Expect(nativeOsmo).To(Equal(coinOsmo))

						// Check that the ibc/uatom were retrieved
						osmoIBCAtom := s.blackChain.App.(*app.Black).BankKeeper.GetBalance(s.blackChain.GetContext(), receiverAcc, uatomOsmoIbcdenom)
						Expect(osmoIBCAtom.IsZero()).To(BeTrue())
						ibcAtom := s.IBCOsmosisChain.GetSimApp().BankKeeper.GetBalance(s.IBCOsmosisChain.GetContext(), senderAcc, uatomIbcdenom)
						Expect(ibcAtom).To(Equal(sdk.NewCoin(uatomIbcdenom, sdk.NewInt(10))))
					})
				})
			})
		})
	})
})
