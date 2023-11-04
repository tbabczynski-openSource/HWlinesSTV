%Author: Emmanuel Maggiori. March 2014.

%Input:
%s: stickness field, be: orientation field, sigma: range parameter

%Output:
%saliency, ballness and orientation fields

function [saliency,ballness,orientation] = vote(s,be,sigma) 

	[height, width] = size(s);

	c0=c(0,s,be);
	c2=c(2,s,be);
	c4=c(4,s,be);
	c6=c(6,s,be);
	c2bar=conj(c2);

	w0=w(0,height,width,sigma);
	w2=w(2,height,width,sigma);
	w4=w(4,height,width,sigma);
	w6=w(6,height,width,sigma);
	w8=w(8,height,width,sigma);

	c0_f=fft2(ifftshift(c0));
	c2_f=fft2(ifftshift(c2));
	c4_f=fft2(ifftshift(c4));
	c6_f=fft2(ifftshift(c6));
	c2bar_f=fft2(ifftshift(c2bar));

	w0_f=fft2(ifftshift(w0));
	w2_f=fft2(ifftshift(w2));	
	w4_f=fft2(ifftshift(w4));		
	w6_f=fft2(ifftshift(w6));
	w8_f=fft2(ifftshift(w8));

	w0_c2bar=w0_f.*c2bar_f; %eight convolutions required

	w2_c0=w2_f.*c0_f;  

	w4_c2=w4_f.*c2_f;

	w6_c4=w6_f.*c4_f;

	w8_c6=w8_f.*c6_f;

	w0_c0=w0_f.*c0_f;

	w2_c2=w2_f.*c2_f;

	w4_c4=w4_f.*c4_f;


	U_minus2= fftshift( ifft2( (w0_c2bar) + 4*(w2_c0) + 6*(w4_c2) + 4*(w6_c4) + (w8_c6) ) );
%   U_minus2= circshift(U_minus2,1-mod([height, width],2));
	U_2=conj(U_minus2);
	U_0=  real( fftshift( ifft2( 6*(w0_c0) + 8*(w2_c2) + 2*(w4_c4) )));
%   U_0= circshift(U_0,1-mod([height, width],2));


	saliency=abs(U_minus2);
	ballness=0.5*(U_0-abs(U_2));
	orientation=0.5*angle(U_minus2);

	%Uncomment to show normalized saliency field:
	%imshow((saliency-min(min(saliency)))./max(max(saliency)));

end
