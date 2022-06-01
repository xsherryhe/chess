require_relative '../../lib/chess_pieces/chess_pawn.rb'

describe Pawn do
  describe '#move' do
    it 'prompts the user to enter a position' do
      
    end

    context 'when a legal position is entered' do
      it "changes the pawn's position to the new position" do
        
      end
    end

    context 'while an illegal position is entered' do
      it 'prompts the user to enter a position until a legal position is entered' do
        
      end
    end

    context 'when a diagonal position is entered' do
      context 'when an opposing piece can be captured (is diagonal from the pawn)' do
        it "allows the pawn's position to be changed" do
          
        end
      end

      context 'when an opposing pawn can be captured en passant' do
        it "allows the pawn's position to be changed" do
        end
      end

      context 'when an opposing piece cannot be captured' do
        it "does not allow the pawn's position to be changed" do
          
        end
      end
    end

    context 'when a double-step position is entered' do
      context 'when the pawn is in starting position' do
        it "allows the pawn's position to be changed" do
        
        end
      end

      context 'when the pawn is not in starting position' do
        it "does not allow the pawn's position to be changed" do
          
        end
      end
    end
  end
end
